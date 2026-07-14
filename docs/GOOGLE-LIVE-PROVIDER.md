# Google Live Voice Provider

## Architecture

```
VoiceProvider interface
    └── GoogleLiveProvider
         ├── google-live-config.ts   — Typed configuration schema
         ├── google-live.ts          — Full VoiceProvider implementation
         └── test-google-live-provider.ts — Local + optional network test
```

The `GoogleLiveProvider` implements the `VoiceProvider` interface from `voice/provider/provider-interface.ts`.

## Provider Properties

| Property              | Value    |
|-----------------------|----------|
| Provider ID           | `google` |
| supportsRealtime()    | `true`   |
| supportsPhoneCalls()  | `false`  |
| Audio format          | opus     |
| Sample rate (input)   | 16 kHz   |
| Connection type       | WebSocket (Google Live BiDi) |

## Credential Detection

The provider detects credentials **without exposing their values**:

1. **Environment variables**: `GEMINI_API_KEY` or `GOOGLE_API_KEY`
2. **OpenClaw catalog**: `~/.openclaw/agents/main/agent/plugins/google/catalog.json`
3. **None**: No credentials found

Detection is purely local — no network request is made to check if keys are valid.

## Offline Test (Default)

```sh
npm run test:google-live
```

This checks only local configuration:
- Are credentials configured (via env or catalog)?
- What is the credential source?
- What is the default model?

No API connection is made. No cost is incurred.

## Optional Network Handshake Test

```sh
GOOGLE_LIVE_NETWORK_TEST=1 npm run test:google-live:network
```

Only with explicit opt-in via environment variable:
- One short WebSocket handshake
- No audio data sent
- No phone call
- Immediate disconnect
- Timeout: 15 seconds maximum
- No secrets or key values printed

## Configuration Fields

See `voice/provider/google-live-config.ts` for the full typed schema.

| Field             | Type    | Default   | Description                       |
|-------------------|---------|-----------|-----------------------------------|
| model             | string  | gemini-2.5-flash-native-audio-preview-12-2025 | Gemini Live model |
| voice             | string  | Kore      | Speaker voice                     |
| language          | string  | de        | Language code                     |
| temperature       | number  | 0.7       | Generation temperature            |
| apiVersion        | string  | v1beta    | Google API version                |
| silenceDetection  | object  | {...}     | VAD configuration                 |
| activityHandling  | string  | interrupt | Activity interruption behavior    |
| thinkingLevel     | string  | medium    | Thinking level                    |
| thinkingBudget    | number  | 8192      | Thinking token budget             |
| sessionTimeoutMs  | number  | 120000    | Session timeout in milliseconds   |
| toolPolicy        | string  | safe-read-only | Tool execution policy        |
| consultPolicy     | string  | auto      | Consult policy                    |

## Safety

- **No real phone calls**: `supportsPhoneCalls()` returns `false`
- **No network on import**: The provider only connects when `connect()` is explicitly called
- **Credential-safe**: Key values are never logged or printed
- **AbortController**: All connections use `AbortController` for clean teardown
- **Timeout**: Configurable session timeout (default: 120s)
- **approval-system**: Unchanged; all real calls require approval

## Known Limitations

- Google Live API requires an active internet connection
- The Gemini Live model has rate limits on the free tier:
  - 10 requests per minute (free tier)
  - 1,500 requests per day (free tier)
  - Higher limits with paid tier
- Latency varies: typically 500-1500ms for first response
- No PSTN telephony support (no phone numbers)

## Error Scenarios

| Error                      | Cause                                      |
|----------------------------|--------------------------------------------|
| `not connected`            | `sendAudio()` or `receiveAudio()` before connect |
| `providerId is required`   | Missing providerId in connect config        |
| `sessionId is required`    | Missing sessionId in connect config         |
| `connection aborted`       | AbortController triggered during handshake  |
| Timeout                    | No response within sessionTimeoutMs         |
| Invalid API key            | Credentials rejected by Google API          |

## Teardown

To remove the Google Live provider:

1. Delete `voice/provider/google-live.ts`
2. Delete `voice/provider/google-live-config.ts`
3. Delete `scripts/test-google-live-provider.ts`
4. Remove scripts from `package.json`
5. Remove `GoogleLiveProvider` references from `voice/pipeline/pipeline.ts`
6. Delete `docs/GOOGLE-LIVE-PROVIDER.md`
7. Revert changes to `docs/LIVE-VOICE-ARCHITECTURE.md` and `docs/GEMINI-LIVE-STATUS.md`
