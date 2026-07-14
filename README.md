# Sagent Lab

Backend-, Orchestrierungs- und Policy-Schicht für lokale KI-Agenten.

- Kein eigenes Frontend
- OpenClaw als zentrale Agentenplattform
- OpenCode als Coding Worker

## Aktuelle Funktionen

- **Sagent Bridge** (`scripts/sagent-task.sh`): Task-Eingabe, Risikoklassifizierung, Approval-Flow, Routing zu OpenClaw oder OpenCode
- **Security Supervisor**: Drei Modi (always_ask, approve_dangerous, full_access), Risiko-Level 0-6
- **Approval Flow**: Manuelle Freigabe für risikoreiche Tasks
- **Auto-Code Routing**: Automatische Erkennung und Weiterleitung von Coding-Tasks an OpenCode
- **ntfy-Integration**: Push-Benachrichtigungen bei ausstehenden Approvals
- **Healthchecks**: OpenClaw-Status und Modellprüfung
- **OpenCode Worker**: Isolierter Coding-Worker für Code-Änderungen
- **Voice Call MVP** (`scripts/sagent-call.sh`): Sichere, lokale Sprachruf-Simulation und Auftragsverwaltung. Keine echten Anrufe ohne manuelle Freigabe.

## Projektstruktur

```
scripts/
  sagent-task.sh           # Zentraler Task-Handler (Einstiegspunkt)
  sagent-approval.sh       # Approval-Flow (approve/deny/status)
  sagent-healthcheck.sh    # OpenClaw-Healthcheck
  sagent-notify.sh         # ntfy-Push-Benachrichtigungen
  sagent-opencode-worker.sh # OpenCode-Worker
  sagent-set-security.sh   # Security-Mode-Konfiguration
  sagent-set-auto-code.sh  # Auto-Code-Routing-Konfiguration
  sagent-set-ntfy.sh       # ntfy-Konfiguration
  sagent-status.sh         # Status-Anzeige
  sagent-call.sh           # Voice Call MVP
docs/
  COMMANDS.md              # Detaillierte Befehlsreferenz
  VOICE-CALLS.md           # Voice Call Dokumentation
  APPROVAL-FLOW.md         # Approval-Flow-Dokumentation
  ...
```

## Installation

```sh
git clone <repo-url> sagent-lab
cd sagent-lab
npm install
```

Voraussetzungen: Node.js, openclaw CLI.

## Wichtige Commands

```sh
scripts/sagent-task.sh "/help"
scripts/sagent-task.sh "/status"
scripts/sagent-task.sh "/security"
scripts/sagent-task.sh "/call setup"
scripts/sagent-task.sh "/call check"
scripts/sagent-task.sh "/call gemini-check"
scripts/sagent-task.sh "/call mock +491234567890 --language de --goal \"Termin\""
scripts/sagent-task.sh "/call +491234567890 --language de --goal \"Termin\""
scripts/sagent-task.sh "Deine Aufgabe an OpenClaw"
```

Siehe `docs/COMMANDS.md` für die vollständige Befehlsreferenz.

## Entwicklungsstatus

Experimentell. Lokaler Prototyp für Sagent v2.
