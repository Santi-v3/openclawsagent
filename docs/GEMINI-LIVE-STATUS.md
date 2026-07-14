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
| GoogleLiveProvider Code         | implementiert |
| google-live-config.ts           | vorhanden  |
| test-google-live-provider.ts    | vorhanden  |

## Prüfung

Lokale Konfigurationsprüfung (keine API-Verbindung, keine Kosten):

```sh
npm run test:google-live
```

Erweiterte Prüfung über sagent-call.sh:

```sh
scripts/sagent-call.sh gemini-check
```

Optionaler Netzwerk-Handshake (nur mit explizitem Opt-in):

```sh
GOOGLE_LIVE_NETWORK_TEST=1 npm run test:google-live:network
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
9. GoogleLiveProvider implementiert und typisiert

## Sicherheit

- Der Gemini-Live-Provider wird NIE automatisch aktiviert.
- `allowRealCalls` ist standardmäßig `false`.
- `requireApproval` ist standardmäßig `true`.
- Der Provider bleibt bis zur manuellen Freigabe auf `mock`.
- `supportsPhoneCalls()` gibt `false` zurück – kein echter Telefonanbieter.
- Keine Netzwerkverbindung beim Import – nur bei explizitem `connect()`.
- Credentials werden nie ausgegeben, nur als `configured`/`not configured` gemeldet.
- AbortController und Timeout für sauberes Teardown.

## Konfiguration

1. Beispielkonfiguration kopieren:
   ```sh
   cp config/voice-call-gemini-live.example.json5 config/voice-call-gemini-live.json
   ```
2. API-Key über `GEMINI_API_KEY` setzen (nie in der Config-Datei speichern).
3. Provider in `config/voice-call-gemini-live.json` auf `"google-realtime"` setzen.
4. `allowRealCalls` nur nach manueller Prüfung auf `true` setzen.
5. Für TypeScript-Typen siehe `voice/provider/google-live-config.ts`.

## Tests

```
npm run test:google-live        — lokale Config-Prüfung (Default)
npm run test:google-live:network — optionaler Handshake (nur mit GOOGLE_LIVE_NETWORK_TEST=1)
```

## GoogleLiveProvider Implementation

- **Datei**: `voice/provider/google-live.ts`
- **Interface**: `VoiceProvider` aus `voice/provider/provider-interface.ts`
- **Credentials**: Erkennt `GEMINI_API_KEY` / `GOOGLE_API_KEY` (env) oder OpenClaw Catalog
- **Status**: `idle → connecting → connected → disconnected → error`
- **AbortController**: Sauberer Abbruch bei Timeout/Fehler
- **Keine Secrets**: Key-Werte werden nie geloggt
- **Mock unverändert**: `MockVoiceProvider` bleibt voll funktionsfähig

## Bekannte Einschränkungen

- Gemini Live erfordert eine aktive Internetverbindung.
- Der google-realtime-Provider in OpenClaw muss installiert sein.
- Echte Anrufe (allowRealCalls=true) sind als Risk Level 4 klassifiziert.
- Ein gemini-check allein aktiviert noch keinen Echtmodus.
- Free-Tier: 10 requests/min, 1,500 requests/day.
- Latenz: 500-1500ms typisch für erste Antwort.
- Kein PSTN / keine Telefonnummern.
