# Live Voice Architecture

## Overview

Modular voice engine for Sagent. Supports real-time voice streaming and
telephony through a provider abstraction layer.

## Components

```
voice/
├── provider/
│   ├── provider-interface.ts   — VoiceProvider interface + shared types
│   ├── mock.ts                 — Mock provider (no real calls)
│   ├── google-live.ts          — Google Live API placeholder
│   └── twilio.ts               — Twilio telephony placeholder
├── session/
│   └── voice-session.ts        — Session lifecycle management
├── pipeline/
│   └── pipeline.ts             — End-to-end orchestration
├── transcript/
│   └── transcript.ts           — Transcript types + processing
└── summary/
    └── summary.ts              — Summary types + processing
```

## Data Flow

```
VoiceSession
    ↓  manages lifecycle
VoiceProvider
    ↓  bidirectional audio
Pipeline
    ↓  orchestration
Transcript
    ↓  text output
Summary
    ↓  structured result
JSON Output
```

## Provider Interface

| Method              | Returns               | Description                    |
|---------------------|-----------------------|--------------------------------|
| `connect()`         | `Promise<void>`       | Open connection                |
| `disconnect()`      | `Promise<void>`       | Close connection               |
| `sendAudio()`       | `Promise<void>`       | Send audio chunk               |
| `receiveAudio()`    | `AsyncGenerator`      | Receive audio stream           |
| `supportsRealtime()`| `boolean`             | Real-time streaming support    |
| `supportsPhoneCalls()`| `boolean`           | PSTN telephony support         |

## Provider Comparison

| Feature          | Mock | Google Live | Twilio |
|------------------|------|-------------|--------|
| Real-time audio  | yes  | yes         | no     |
| Phone calls      | no   | no          | yes    |
| Audio format     | pcm16| opus        | mulaw  |
| API key needed   | no   | yes         | yes    |
| Implementation   | full | placeholder | placeholder |

## Session States

```
idle → connecting → connected → disconnected
                        ↓
                     error
```

## Future Extensions

- Real Google Live API integration (WebRTC, streaming recognition)
- Twilio Voice SDK + Media Streams integration
- TTS output via provider
- Multi-provider routing and fallback
- Persistent session storage
- VAD (Voice Activity Detection)
- Diarization (speaker separation)
- Live transcription streaming to UI via WebSocket
- MCP tools for voice control
