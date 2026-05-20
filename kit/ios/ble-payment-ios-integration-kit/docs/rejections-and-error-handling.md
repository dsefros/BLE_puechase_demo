# Rejections and Error Handling

Commonly emitted now:
- `unsupportedVersion`
- `missingRequiredField`
- `malformedPayload`
- `signalBelowThreshold`
- `packetTooShort`

Present in public enum but currently not emitted by processing path: `invalidPrefix`, `weakRSSI`, `expiredPacket`, `duplicatePacket`, `invalidQrcId`, `unknown`.

Recommendation: treat rejections as scan-noise diagnostics, and avoid showing raw reject reasons directly to end users.
