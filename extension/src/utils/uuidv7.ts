/**
 * RFC 9562 compliant UUIDv7 generator for browser extension.
 * Combines 48-bit millisecond unix timestamp with cryptographically random bits.
 */
export function generateUuidV7(): string {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);

  const now = Date.now();
  // 48-bit timestamp (ms) in bytes 0..5
  bytes[0] = Math.floor(now / 0x10000000000) & 0xff;
  bytes[1] = Math.floor(now / 0x100000000) & 0xff;
  bytes[2] = Math.floor(now / 0x1000000) & 0xff;
  bytes[3] = Math.floor(now / 0x10000) & 0xff;
  bytes[4] = Math.floor(now / 0x100) & 0xff;
  bytes[5] = now & 0xff;

  // Version 7 in byte 6 (0111 xxxx)
  bytes[6] = (bytes[6] & 0x0f) | 0x70;
  // Variant 1 in byte 8 (10xx xxxx)
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  let hex = "";
  for (let i = 0; i < 16; i++) {
    const byte = bytes[i].toString(16).padStart(2, "0");
    hex += byte;
    if (i === 3 || i === 5 || i === 7 || i === 9) {
      hex += "-";
    }
  }
  return hex;
}
