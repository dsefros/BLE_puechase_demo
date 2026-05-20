# Rejections and error handling

## Currently emitted by Android implementation

- `missingRequiredField`
- `malformedPayload`
- `unsupportedVersion`
- `packetTooShort`
- `signalBelowThreshold`
- `unknown` (fallback when an unexpected non-`PacketRejected` error escapes internals)

## Present in enum but currently not emitted by Android implementation

- `invalidPrefix`
- `weakRSSI`
- `expiredPacket`
- `duplicatePacket`
- `invalidQrcId`

## Host-app guidance

- Treat most rejects as expected noise during scanning.
- Keep reject reasons in debug logs/telemetry rather than user-facing UI copy.
- Use `Accepted` to drive UX transitions; define clear scanner stop policy after first acceptable candidate.
