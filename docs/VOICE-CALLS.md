# Sagent Voice Calls

## Overview

The Sagent Voice Call MVP provides safe, local voice call simulation and request management. No real calls are made without explicit manual approval.

The implementation uses the existing OpenClaw voice call plugin infrastructure but isolates all real call initiation behind a pending-approval workflow.

## Architecture

```
scripts/sagent-task.sh  (/call ...)
        |
        v
scripts/sagent-call.sh  (all voice call logic)
        |
        v
~/.openclaw/workspace/calls/
    |-- pending/   (request creates files here)
    |-- active/    (mock creates files here)
    |-- history/   (archived call records)
    |-- last-call.json  (latest call record)
```

## Commands

### setup

```sh
scripts/sagent-call.sh setup
```

Runs only safe checks: verifies workspace directories exist, checks for `openclaw` binary. No external actions, no configuration changes.

### check

```sh
scripts/sagent-call.sh check
```

Runs `openclaw voicecall setup --json` to verify the voice call plugin is available and configured.

### gemini-check

```sh
scripts/sagent-call.sh gemini-check
```

Checks Gemini Live voice provider readiness:

- openclaw binary and voicecall plugin
- Current provider (mock or google-realtime)
- Gemini config file (`voice-call-gemini-live.json`)
- Mock config file (`voice-call-mock.json`)
- System prompt file (`voice-call-system-prompt.txt`)
- Gemini credentials (environment variable or OpenClaw catalog)

No changes are made to the provider configuration.

### twilio-check

```sh
scripts/sagent-call.sh twilio-check
```

Checks Twilio telephony provider readiness:

- Twilio credentials (Account SID, Auth Token, From Number)
- Webhook URL configuration
- Voice call plugin installation
- Google Realtime provider registration
- Live config preparation (`voice-call-twilio-gemini.json`)

No credentials are displayed. No real call is made. No configuration is changed.

### mock

```sh
scripts/sagent-call.sh mock +491234567890 --language de --goal "Termin bestätigen"
```

Simulates a voice call using the mock provider only. Never uses `--yes`. Produces a simulated transcript and summary. No real call is made.

### request

```sh
scripts/sagent-call.sh request +491234567890 --language de --goal "Termin bestätigen"
```

Validates all inputs (E.164 phone number, ISO language code, goal length), then creates a pending call job under `~/.openclaw/workspace/calls/pending/`. No real call is started.

### status

```sh
scripts/sagent-call.sh status
```

Reads local call data directories and displays counts of pending, active, and history calls. Lists pending files with masked phone numbers.

### last

```sh
scripts/sagent-call.sh last
```

Reads `~/.openclaw/workspace/calls/last-call.json` and displays the most recent call metadata with masked phone number.

### transcript

```sh
scripts/sagent-call.sh transcript
```

Displays the transcript from the last mock call (if available).

### summarize

```sh
scripts/sagent-call.sh summarize
```

Displays a summary of the last call from either the summary file or call metadata.

## Security

- **No real calls** are made by any command. `request` only creates pending files.
- `mock` is hard-coded to use the mock provider and rejects `--yes`.
- All phone numbers are masked in normal output (e.g. `+49******7890`).
- No secrets, tokens, or credentials are read or displayed.
- Real outgoing calls are classified as Risk Level 4 in the Sagent approval flow.

## Workspace Structure

```
~/.openclaw/workspace/calls/
    |-- pending/        # JSON files for pending call requests
    |-- active/         # JSON files for active/mock call sessions
    |-- history/        # Archived call records
    |-- last-call.json  # Symlink or copy of the most recent call record
```

### Pending call file format (`pending/pending-<timestamp>.json`)

```json
{
  "timestamp": "20260714-120000",
  "number": "+491234567890",
  "language": "de",
  "goal": "Termin bestätigen",
  "status": "pending",
  "type": "voice_call_request"
}
```

### Mock call file format (`active/call-<timestamp>.json`)

```json
{
  "timestamp": "20260714-120000",
  "number": "+491234567890",
  "language": "de",
  "goal": "Termin bestätigen",
  "provider": "mock",
  "status": "simulated",
  "type": "mock",
  "real_call": false
}
```

## Configuration Files

```
config/
  voice-call-gemini-live.example.json5          Gemini Live provider example config
  voice-call-mock.example.json5                 Mock provider example config
  voice-call-twilio-gemini.example.json5        Twilio + Gemini Live example config
  voice-call-system-prompt.txt                  System prompt for voice calls
```

- Copy `voice-call-gemini-live.example.json5` → `voice-call-gemini-live.json` for Gemini Live setup.
- Copy `voice-call-mock.example.json5` → `voice-call-mock.json` for custom mock settings.
- Copy `voice-call-twilio-gemini.example.json5` → `voice-call-twilio-gemini.json` for Twilio setup.
- The system prompt is always read from `voice-call-system-prompt.txt`.

## See Also

- `docs/GEMINI-LIVE-STATUS.md` – Gemini Live provider readiness details
- `docs/COMMANDS.md` – Full command reference
- `docs/TWILIO-PROVIDER.md` – Twilio provider details
- `docs/GOOGLE-LIVE-PROVIDER.md` – Google Live provider details

## Testing

Run `bash -n scripts/sagent-call.sh` to verify syntax.

Test scenarios:
- `mock` with valid E.164 number succeeds
- `mock` with invalid number fails with clear error
- `mock` with `--yes` is rejected
- `request` creates a pending file
- `request` with missing goal fails
- `gemini-check` runs without errors (even without credentials)
- Unknown slash commands in `sagent-task.sh` remain blocked
