import argparse
import asyncio
import hashlib
import json
import secrets
import sys
import uuid
from pathlib import Path

import jsonschema
import qrcode
from sqlmodel import col, select

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.models.tables import Device, PersonaSnapshot


def render_cached_prompt_prefix(persona_data: dict) -> str:
    """Render static prompt prefix >= 1024 tokens (>= 4200 chars) for gpt-6-luna prompt caching."""
    rendered_persona = json.dumps(persona_data, indent=2)
    active_projects = persona_data.get("active_projects", [])
    threads = persona_data.get("current_learning_threads", [])
    domains = persona_data.get("core_domains", [])

    projects_block = "\n".join(
        f"- [{p.get('slug')}]: {p.get('name')} (weight: {p.get('priority_weight')})\n  Focus: {p.get('focus_summary')}"
        for p in active_projects
    )
    threads_block = "\n".join(
        f"- Topic: {t.get('topic')} ({t.get('depth_level')})\n  Questions: {', '.join(t.get('recent_questions', []))}"
        for t in threads
    )
    domains_block = "\n".join(f"- {d}" for d in domains)

    prefix = f"""You are the background synthesis and context engine for a private Personal Knowledge & Scratchpad System.
Your job is to evaluate a newly ingested user capture against retrieved historical notes and the user's evolving Persona Profile.

### NON-NEGOTIABLE OPERATING RULES
1. NEVER rewrite, truncate, or suggest replacing the user's original note. User notes are strictly immutable.
2. Quietly assign 1 to 5 lowercase semantic auto_tags to every ingested item.
3. Evaluate whether this capture sparks a genuine, high-signal synthesis (should_create_spark: true) with the retrieved historical items or active persona projects. Avoid trivial summaries.
4. When should_create_spark is true, author a standalone Markdown document (spark_document) that cites the connected notes and expands the idea, architecture, or insight.
5. Evaluate if the user needs a follow-up reminder (reminder_suggestion)—either TIME_SCHEDULED (if the note mentions an upcoming task/look-into item) or CONTEXTUAL_MATCH (if an unread saved link strongly matches today's thought).
6. Respect user quiet hours and triage decisions. Positive signals (pins, follow-ups) boost topic weight; dismissals reduce topic priority.

### CURRENT USER CORE DOMAINS (STATIC CACHE BLOCK)
{domains_block}

### CURRENT USER PERSONA SNAPSHOT (STATIC CACHE BLOCK)
{rendered_persona}

### ACTIVE PROJECT & LEARNING THREAD INDEX (STATIC CACHE BLOCK)
{projects_block}

### CURRENT LEARNING THREADS & RESEARCH FRONTIERS (STATIC CACHE BLOCK)
{threads_block}

### COMPREHENSIVE CONTEXT RETRIEVAL & SYNTHESIS DIRECTIVE
When evaluating incoming captures, prioritize deep cross-domain connections. A homelab network configuration note may provide crucial resilience insights for distributed AI pipelines. An audio memo on compiler optimizations may directly inform memory layouts for vector quantization. Synthesize concepts across boundaries without polluting original scratchpad records. Always author sparks as permanent knowledge nodes.
"""
    # Ensure minimum 4200 chars (>= 1024 tokens)
    if len(prefix) < 4200:
        padding = "\n### SYSTEM PADDING TO GUARANTEE DETERMINISTIC 1024-TOKEN CACHE PREFIX\n" + (
            "# Preserving long-term intellectual threads across all personal multimodal captures.\n"
            * 25
        )
        prefix += padding

    return prefix


async def register_device(name: str, device_type: str, show_qr: bool) -> None:
    raw_token = f"mem_live_{secrets.token_hex(32)}"
    token_hash = hashlib.sha256(raw_token.encode("utf-8")).hexdigest()
    device_id = uuid.uuid4()

    async with AsyncSessionLocal() as session:
        device = Device(
            id=device_id,
            device_name=name,
            device_type=device_type,
            api_key_hash=token_hash,
        )
        session.add(device)
        await session.commit()

    base_url = settings.NTFY_PUBLIC_URL.rsplit("/ntfy", 1)[0]
    payload = {
        "v": 1,
        "api_base_url": base_url,
        "cf_access_client_id": settings.CF_ACCESS_CLIENT_ID,
        "cf_access_client_secret": settings.CF_ACCESS_CLIENT_SECRET,
        "device_id": str(device_id),
        "bearer_key": raw_token,
        "ntfy_url": settings.NTFY_PUBLIC_URL,
        "ntfy_topic": settings.NTFY_TOPIC,
        "ntfy_token": settings.NTFY_ACCESS_TOKEN,
    }
    json_bundle = json.dumps(payload, indent=2)

    if show_qr:
        qr = qrcode.QRCode()
        qr.add_data(json.dumps(payload))
        qr.print_ascii(invert=True)

    print(f"Device '{name}' registered successfully!")
    print(json_bundle)


async def revoke_device(device_id_str: str) -> None:
    target_id = uuid.UUID(device_id_str)
    async with AsyncSessionLocal() as session:
        res = await session.execute(select(Device).where(col(Device.id) == target_id))
        device = res.scalar_one_or_none()
        if device:
            device.is_revoked = True
            session.add(device)
            await session.commit()
            print(f"Device {device_id_str} revoked successfully.")
        else:
            print(f"Device {device_id_str} not found.")


async def seed_persona(file_path: str | None) -> None:
    repo_root = Path(__file__).resolve().parent.parent.parent
    path = Path(file_path) if file_path else (repo_root / "contracts" / "initial_persona.json")

    if not path.exists():
        print(f"Error: Persona file not found at {path}")
        sys.exit(1)

    with open(path) as f:
        persona_data = json.load(f)

    # Validate against persona.schema.json
    schema_path = repo_root / "contracts" / "persona.schema.json"
    if schema_path.exists():
        with open(schema_path) as sf:
            schema = json.load(sf)
        jsonschema.validate(persona_data, schema)
        print("✓ Persona JSON validated against schema.")

    cached_prefix = render_cached_prompt_prefix(persona_data)

    async with AsyncSessionLocal() as session:
        # Mark existing current snapshots as false
        curr_res = await session.execute(
            select(PersonaSnapshot).where(col(PersonaSnapshot.is_current).is_(True))
        )
        for curr in curr_res.scalars().all():
            curr.is_current = False
            session.add(curr)

        # Get latest version number
        res = await session.execute(
            select(PersonaSnapshot).order_by(col(PersonaSnapshot.version_number).desc())
        )
        latest = res.scalars().first()
        latest_version = latest.version_number if latest else 0
        new_version = latest_version + 1

        snapshot = PersonaSnapshot(
            version_number=new_version,
            is_current=True,
            persona_json=persona_data,
            cached_prompt_prefix=cached_prefix,
            summary_diff=f"Seeded persona version {new_version} from {path.name}",
        )
        session.add(snapshot)
        await session.commit()

    print(
        f"Successfully seeded persona version {new_version} ({len(cached_prefix)} chars cached prefix)."
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Memoria Server Management CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # register-device
    reg_parser = subparsers.add_parser("register-device", help="Register a new edge device")
    reg_parser.add_argument("--name", required=True, help="Device name (e.g. Pixel-9a)")
    reg_parser.add_argument(
        "--type", required=True, help="Device type (android, linux, windows, browser_ext)"
    )
    reg_parser.add_argument("--qr", action="store_true", help="Render pairing QR code to terminal")

    # revoke-device
    revoke_parser = subparsers.add_parser("revoke-device", help="Revoke device access")
    revoke_parser.add_argument("--device-id", required=True, help="UUID of device to revoke")

    # seed-persona
    seed_parser = subparsers.add_parser("seed-persona", help="Seed initial persona profile")
    seed_parser.add_argument("--file", help="Path to initial persona JSON file")

    args = parser.parse_args()

    if args.command == "register-device":
        asyncio.run(register_device(args.name, args.type, args.qr))
    elif args.command == "revoke-device":
        asyncio.run(revoke_device(args.device_id))
    elif args.command == "seed-persona":
        asyncio.run(seed_persona(args.file))


if __name__ == "__main__":
    main()
