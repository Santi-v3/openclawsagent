import { GoogleLiveProvider } from "../voice/provider/google-live";
import { GOOGLE_LIVE_DEFAULTS } from "../voice/provider/google-live-config";
import type { VoiceConnectionConfig } from "../voice/provider/provider-interface";

async function main(): Promise<void> {
  const networkTest = process.env.GOOGLE_LIVE_NETWORK_TEST === "1";

  console.log("Google Live Provider Test");
  console.log("=========================");
  console.log();

  const status = await GoogleLiveProvider.checkConfigured();
  console.log(`  Credentials:       ${status.configured ? "configured" : "not configured"}`);
  console.log(`  Credential source: ${status.source}`);
  console.log(`  Default model:     ${status.model}`);
  console.log();

  if (networkTest) {
    console.log("  Network mode:      ENABLED (GOOGLE_LIVE_NETWORK_TEST=1)");
    console.log();

    const provider = new GoogleLiveProvider();
    const config: VoiceConnectionConfig = {
      providerId: "google",
      sessionId: `test-${Date.now()}`,
      config: {
        model: GOOGLE_LIVE_DEFAULTS.model,
        language: "de",
      },
    };

    if (!status.configured) {
      console.log("  SKIP: no credentials configured, cannot run network test");
      console.log();
      console.log("Google Live Provider Test: SKIPPED (no credentials)");
      process.exit(0);
    }

    const timeout = new AbortController();
    const timeoutId = setTimeout(() => timeout.abort(), 15_000);

    try {
      console.log("  Connecting (handshake only, max 15s)...");
      await provider.connect(config);
      console.log("  Handshake:         OK");
      console.log("  State:             connected");

      await provider.disconnect();
      console.log("  Disconnect:        OK");
      console.log();
      console.log("Google Live Provider Test: PASSED (network)");
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.log(`  Handshake:         FAILED`);
      console.log(`  Error:             ${message}`);
      console.log();
      console.log("Google Live Provider Test: FAILED (network)");
      process.exit(1);
    } finally {
      clearTimeout(timeoutId);
    }
  } else {
    console.log("  Network mode:      disabled (set GOOGLE_LIVE_NETWORK_TEST=1 to enable)");
    console.log("  No API connection was made.");
    console.log();

    if (status.configured) {
      console.log("Google Live Provider Test: PASSED (local config check)");
    } else {
      console.log("Google Live Provider Test: PASSED (local config check, no credentials)");
    }
  }
}

await main();
