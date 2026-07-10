# Sagent OpenCode Worker

## Purpose

The OpenCode worker lets Sagent delegate explicit coding tasks to OpenCode without sending every normal task through OpenCode automatically.

For the MVP, OpenCode runs only when the user calls an explicit slash command or direct worker script.

## Model

Default model:

```text
opencode/deepseek-v4-flash-free
```

Override locally for one run:

```sh
SAGENT_OPENCODE_MODEL=opencode/north-mini-code-free scripts/sagent-opencode-worker.sh "<task>"
```

## Direct Usage

```sh
scripts/sagent-opencode-worker.sh "<coding task>"
```

Example:

```sh
scripts/sagent-opencode-worker.sh "Erkläre kurz die Aufgabe dieses Repos. Ändere keine Dateien."
```

## Slash Usage

```sh
scripts/sagent-task.sh "/opencode <coding task>"
scripts/sagent-task.sh "/code <coding task>"
```

Examples:

```sh
scripts/sagent-task.sh "/opencode Erkläre kurz scripts/sagent-task.sh. Ändere keine Dateien."
scripts/sagent-task.sh "/code Analysiere scripts/sagent-set-security.sh und schlage Verbesserungen vor. Ändere keine Dateien."
```

## Allowed Folders

The worker runs only from:

- `/Users/santi/Projects`
- `~/.openclaw/workspace`

The worker refuses to run from:

- `/Users/santi`
- `~/Desktop`
- `~/Downloads`
- `~/Documents`
- iCloud Drive
- `~/.ssh`
- `~/.openclaw` except `~/.openclaw/workspace`

Disallowed paths return exit code `30`.

## Safety Prefix

Every OpenCode task is prefixed with:

```text
Du bist der Sagent OpenCode Worker. Arbeite nur im aktuellen Projektordner. Lies keine Secrets. Keine .env, keine SSH Keys, keine Tokens. Kein git push, kein deploy, keine externen Aktionen. Wenn nicht ausdrücklich nach Änderungen gefragt wird, ändere keine Dateien. Fasse Ergebnis und Risiken kurz zusammen.
```

This keeps the worker read-only by default and prevents obvious secret or external-action requests.

## Logs

OpenCode worker output is stored under:

```text
~/.openclaw/workspace/opencode/last-output.txt
~/.openclaw/workspace/opencode/last-status.json
~/.openclaw/workspace/opencode/history/
```

`last-status.json` includes:

- `timestamp`
- `cwd`
- `model`
- `task`
- `output_file`
- `history_file`
- `exit_code`

## OpenClaw Model Diagnostic

If normal OpenClaw tasks return:

```text
Agent couldn't generate a response.
```

try:

```sh
openclaw models set google/gemini-2.5-flash-lite
openclaw gateway restart
scripts/sagent-task.sh "Antworte exakt mit: pong"
```
