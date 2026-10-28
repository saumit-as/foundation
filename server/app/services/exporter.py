from __future__ import annotations

from typing import Any

import yaml

from app.models.tables import AISpark, Capture


def export_spark_to_markdown(
    spark: AISpark,
    connected_captures: list[Capture],
) -> str:
    """Exports an AI Spark as an Obsidian-compatible Markdown document with YAML frontmatter."""
    source_links: list[str] = []
    for c in connected_captures:
        cap_title = (c.title or c.extracted_title or "Untitled Note").replace("|", "-")
        source_links.append(f"[[{c.id}|{cap_title}]]")

    frontmatter_dict: dict[str, Any] = {
        "id": str(spark.id),
        "title": spark.title,
        "type": "ai_spark",
        "created_at": spark.created_at.isoformat() if spark.created_at else None,
        "related_project": spark.related_project,
        "spark_rationale": spark.spark_rationale,
        "is_pinned": spark.is_pinned,
        "source_links": source_links,
    }

    yaml_header = yaml.dump(frontmatter_dict, sort_keys=False, allow_unicode=True).strip()

    # Immutable source quotes
    sources_section = ["## Source Captures (Immutable)"]
    for c in connected_captures:
        cap_title = c.title or c.extracted_title or "Untitled Note"
        quote_text = (c.raw_text or c.extracted_markdown or "").strip()
        quoted_lines = "\n".join([f"> {line}" for line in quote_text.splitlines()]) if quote_text else "> (Empty)"
        sources_section.append(f"### [[{c.id}|{cap_title}]]\n{quoted_lines}")

    return f"---\n{yaml_header}\n---\n\n{spark.spark_markdown.strip()}\n\n" + "\n\n".join(sources_section) + "\n"
