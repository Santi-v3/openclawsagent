# Gemini Live Voice Provider – Status

## Readiness

| Prüfpunkt                       | Status      |
|---------------------------------|-------------|
| openclaw-Binary                 | erforderlich |
| voicecall-Plugin                | erforderlich |
| Google-Realtime-Provider        | erforderlich |
| Gemini-API-Key (env oder catalog)| erforderlich |
| gemini-live-Konfigurationsdatei | optional    |
| System-Prompt-Datei             | vorhanden  |

## Prüfung

```sh
scripts/sagent-call.sh gemini-check
```

Führt folgende Checks durch:

1. **openclaw** binary vorhanden
2. **voicecall setup --json** erfolgreich ausführbar
3. Aktueller Provider (mock oder google-realtime)
4. Plugin-Status (enabled/disabled)
5. Gemini-Live-Konfigurationsdatei vorhanden (`config/voice-call-gemini-live.json`)
6. Mock-Konfigurationsdatei vorhanden (`config/voice-call-mock.json`)
7. System-Prompt-Datei vorhanden (`config/voice-call-system-prompt.txt`)
8. Gemini Credentials (env var oder OpenClaw catalog)

## Sicherheit

- Der Gemini-Live-Provider wird NIE automatisch aktiviert.
- `allowRealCalls` ist standardmäßig `false`.
- `requireApproval` ist standardmäßig `true`.
- Der Provider bleibt bis zur manuellen Freigabe auf `mock`.

## Konfiguration

1. Beispielkonfiguration kopieren:
   ```sh
   cp config/voice-call-gemini-live.example.json5 config/voice-call-gemini-live.json
   ```
2. API-Key über `GEMINI_API_KEY` setzen (nie in der Config-Datei speichern).
3. Provider in `config/voice-call-gemini-live.json` auf `"google-realtime"` setzen.
4. `allowRealCalls` nur nach manueller Prüfung auf `true` setzen.

## Bekannte Einschränkungen

- Gemini Live erfordert eine aktive Internetverbindung.
- Der google-realtime-Provider in OpenClaw muss installiert sein.
- Echte Anrufe (allowRealCalls=true) sind als Risk Level 4 klassifiziert.
- Ein gemini-check allein aktiviert noch keinen Echtmodus.
