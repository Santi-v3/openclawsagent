# Twilio Telephony Provider

## Architecture

```
VoiceProvider interface
    └── TwilioProvider
         ├── twilio-config.ts   — Typed configuration schema
         ├── twilio.ts          — Full VoiceProvider implementation
         └── test-twilio-provider.ts — Local + optional network test
```

The `TwilioProvider` implements the `VoiceProvider` interface from `voice/provider/provider-interface.ts`.

## Role

Twilio acts as the **telephony transport layer**. It handles PSTN (Public Switched Telephone Network) connectivity — making and receiving real phone calls.

Google Gemini Live acts as the **realtime speech engine** — handling natural conversation, VAD, and speech synthesis. When both are active, Twilio bridges the phone audio stream to Gemini Live for processing.

## Provider Properties

| Property              | Value    |
|-----------------------|----------|
| Provider ID           | `twilio` |
| supportsRealtime()    | `false`  |
| supportsPhoneCalls()  | `true`   |
| Audio format          | mulaw    |
| Sample rate           | 8 kHz    |
| Connection type       | HTTP Webhook + WebSocket Media Stream |

## Credential Detection

The provider detects credentials **without exposing their values**:

1. **`TWILIO_ACCOUNT_SID`** — Twilio account identifier
2. **`TWILIO_AUTH_TOKEN`** — Twilio API authentication token
3. **`TWILIO_FROM_NUMBER`** — E.164 phone number for outbound calls

Detection is purely local — no network request is made.

## Required Environment Variables

| Variable              | Purpose                        | Required For |
|-----------------------|--------------------------------|--------------|
| `TWILIO_ACCOUNT_SID`  | Twilio Account SID             | API auth     |
| `TWILIO_AUTH_TOKEN`   | Twilio Auth Token              | API auth + webhook signature verification |
| `TWILIO_FROM_NUMBER`  | Sender number (E.164)          | Outbound calls |
| `TWILIO_PUBLIC_URL`   | Public webhook URL             | Webhook reachability |

## Offline Test (Default)

```sh
npm run test:twilio
```

This checks only local configuration:
- Are Twilio credentials configured (via env)?
- E.164 validation works correctly
- Phone number masking works correctly
- Provider interface methods return expected values
- Connect/disconnect lifecycle works

No API connection is made. No cost is incurred.

## Optional Credential Reachability Test

```sh
TWILIO_NETWORK_TEST=1 npm run test:twilio:network
```

Only with explicit opt-in via environment variable:
- Tests that config is loadable with credentials
- No call is made
- No message is sent
- No number is purchased
- Timeout: 15 seconds maximum
- No secrets or credential values printed

## Twilio Configuration Fields

See `voice/provider/twilio-config.ts` for the full typed schema.

| Field                 | Type    | Default         | Description                       |
|-----------------------|---------|-----------------|-----------------------------------|
| accountSid            | string  | env `TWILIO_ACCOUNT_SID` | Twilio Account SID      |
| authToken             | string  | env `TWILIO_AUTH_TOKEN`  | Twilio Auth Token       |
| fromNumber            | string  | env `TWILIO_FROM_NUMBER` | E.164 sender number     |
| toNumber              | string  | —               | Default destination number        |
| region                | string  | us1             | Twilio API region                 |
| webhookUrl            | string  | —               | Public webhook URL override       |
| webhookPath           | string  | /voice/webhook  | Webhook endpoint path             |
| tunnelProvider        | string  | none            | ngrok / tailscale-serve / tailscale-funnel |
| ringTimeoutMs         | number  | 30000           | Ring timeout in milliseconds      |
| maxDurationSeconds    | number  | 300             | Maximum call duration in seconds  |
| maxConcurrentCalls    | number  | 1               | Maximum parallel calls            |
| outboundDefaultMode   | string  | conversation    | notify or conversation            |
| realtime              | object  | —               | Realtime voice engine config      |
| skipSignatureVerification | boolean | false       | Dev only — never enable in production |
| mediaStreamPath       | string  | /voice/stream   | WebSocket media stream path       |

## Public Webhook URL

Twilio requires a **publicly reachable** webhook URL to deliver call events and audio streams. The URL must NOT be localhost, 127.0.0.1, or a private IP range.

Options for public exposure:

1. **Tailscale Funnel** — exposes a local port to the public internet
   ```sh
   openclaw voicecall expose --mode funnel
   ```

2. **ngrok** — creates a public tunnel to localhost
   ```json5
   tunnel: { provider: "ngrok" }
   ```

3. **Static public URL** — if you have a public domain
   ```json5
   publicUrl: "https://voice.example.com/voice/webhook"
   ```

## Twilio Signature Verification

Twilio signs every webhook request using HMAC-SHA1 with the Auth Token. The `X-Twilio-Signature` header is verified against:
- The full request URL (including query parameters)
- The POST body parameters (sorted alphabetically)

Verification uses timing-safe comparison to prevent timing attacks.

`skipSignatureVerification: true` disables this check (development only).

## Twilio + Google Gemini Live Integration

When both are configured:

1. Twilio receives an incoming call or initiates an outbound call
2. OpenClaw returns TwiML with `<Connect><Stream>` to open a WebSocket media stream
3. Twilio streams G.711 mu-law 8kHz audio over the WebSocket
4. OpenClaw converts mu-law to PCM16 16kHz and sends to Gemini Live
5. Gemini Live processes speech and returns PCM16 24kHz audio
6. OpenClaw converts back to mu-law 8kHz and streams to Twilio

Audio conversion flow:
```
Twilio (G.711 mu-law 8kHz)
    → OpenClaw (convertMulaw8kToPcm16k)
    → Gemini Live (PCM16 16kHz)
    → OpenClaw (convertPcmToMulaw8k)
    → Twilio (G.711 mu-law 8kHz)
```

## Trial Account Limitations

Twilio trial accounts have restrictions:
- Outbound calls only to verified/allowlisted numbers
- Calls play a brief "trial mode" message before connecting
- Limited to specific geographic regions
- Lower rate limits than paid accounts

For production use, upgrade to a paid Twilio account.

## Safety

- **No real phone calls**: The provider only connects when `connect()` is explicitly called
- **No network on import**: No API requests are made at module load time
- **Credential-safe**: Key values are never logged or printed
- **Phone masking**: E.164 numbers are masked in logs (e.g. `+49****7890`)
- **E.164 validation**: Phone numbers are validated before use
- **AbortController**: All connections use `AbortController` for clean teardown
- **Timeout**: Configurable ring timeout (default: 30s)
- **Approval system**: Unchanged; all real calls require Risk Level 4 approval

## Real Call Flow

A real Twilio call requires:
1. Twilio credentials (Account SID, Auth Token)
2. A verified sender number (Twilio-purchased or verified)
3. A publicly reachable webhook URL
4. Sufficient Twilio account balance
5. Explicit user approval (Risk Level 4)

The approval system ensures:
- Human approval required
- Execute only via `execute-pending`
- AI identifies itself as an assistant
- Consent obtained before proceeding
- No bookings, payments, or commitments without new approval
- Maximum 300 seconds duration
- Maximum 1 concurrent call

## Cost and Rate Limit Risks

- **Twilio API costs**: Per-minute charges apply to outbound calls
- **Rate limits**: Twilio imposes rate limits on API calls
- **Trial balance**: Limited trial credit available
- **Free tier Google**: 10 requests/minute limit for Gemini Live

## Teardown

To remove the Twilio provider:

1. Delete `voice/provider/twilio.ts`
2. Delete `voice/provider/twilio-config.ts`
3. Delete `scripts/test-twilio-provider.ts`
4. Remove scripts from `package.json`
5. Remove `TwilioProvider` references from `voice/pipeline/pipeline.ts`
6. Delete `config/voice-call-twilio-gemini.example.json5`
7. Delete `.env.twilio.example`
8. Delete `docs/TWILIO-PROVIDER.md`
9. Revert changes to `docs/LIVE-VOICE-ARCHITECTURE.md` and `docs/VOICE-CALLS.md`
