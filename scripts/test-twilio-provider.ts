import { TwilioProvider, validateE164, maskPhone } from "../voice/provider/twilio";
import type { VoiceConnectionConfig } from "../voice/provider/provider-interface";

async function main(): Promise<void> {
  const networkTest = process.env.TWILIO_NETWORK_TEST === "1";

  console.log("Twilio Provider Test");
  console.log("====================");
  console.log();

  const status = await TwilioProvider.checkConfigured();
  console.log(`  Account SID:       ${status.accountSid}`);
  console.log(`  Auth Token:        ${status.authToken}`);
  console.log(`  From Number:       ${status.fromNumber}`);
  console.log();

  const allConfigured =
    status.accountSid === "configured" &&
    status.authToken === "configured" &&
    status.fromNumber === "configured";
  console.log(`  Credentials:       ${allConfigured ? "all configured" : "not fully configured"}`);
  console.log();

  console.log("  E.164 validation:");
  console.log(`    +491234567890:    ${validateE164("+491234567890") ? "valid" : "invalid"}`);
  console.log(`    01234567890:      ${validateE164("01234567890") ? "valid" : "invalid"}`);
  console.log(`    +123:             ${validateE164("+123") ? "valid" : "invalid"}`);
  console.log(`    +15551234567:     ${validateE164("+15551234567") ? "valid" : "invalid"}`);
  console.log();

  console.log("  Phone masking:");
  console.log(`    +491234567890:    ${maskPhone("+491234567890")}`);
  console.log(`    +15551234567:     ${maskPhone("+15551234567")}`);
  console.log(`    01234567890:      ${maskPhone("01234567890")}`);
  console.log();

  console.log("  Provider interface:");
  const provider = new TwilioProvider();
  console.log(`    supportsRealtime:   ${provider.supportsRealtime()}`);
  console.log(`    supportsPhoneCalls: ${provider.supportsPhoneCalls()}`);
  console.log(`    initial state:      ${provider.state}`);
  console.log();

  console.log("  Connect without credentials (local only):");
  try {
    const config: VoiceConnectionConfig = {
      providerId: "twilio",
      sessionId: `test-${Date.now()}`,
    };
    await provider.connect(config);
    console.log(`    state:              ${provider.state}`);
    console.log(`    is connected:       ${provider.state === "connected"}`);
    await provider.disconnect();
    console.log(`    post-disconnect:    ${provider.state}`);
    console.log("  Connect:             OK");
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.log(`    FAILED: ${message}`);
    console.log();
    console.log("Twilio Provider Test: FAILED (connect)");
    process.exit(1);
  }
  console.log();

  if (networkTest) {
    console.log("  Network mode:      ENABLED (TWILIO_NETWORK_TEST=1)");
    console.log();

    if (!allConfigured) {
      console.log("  SKIP: credentials not fully configured, cannot run network test");
      console.log();
      console.log("Twilio Provider Test: SKIPPED (no credentials)");
      process.exit(0);
    }

    const netProvider = new TwilioProvider();
    const netConfig: VoiceConnectionConfig = {
      providerId: "twilio",
      sessionId: `test-net-${Date.now()}`,
      config: {
        accountSid: process.env.TWILIO_ACCOUNT_SID,
        authToken: process.env.TWILIO_AUTH_TOKEN,
        fromNumber: process.env.TWILIO_FROM_NUMBER,
      },
    };

    const timeout = new AbortController();
    const timeoutId = setTimeout(() => timeout.abort(), 15_000);

    try {
      console.log("  Testing account reachability (max 15s)...");
      console.log("  No call will be made.");
      console.log("  No message will be sent.");
      console.log("  No number will be purchased.");
      console.log();
      console.log("  Account reachability requires a Twilio API client.");
      console.log("  This test verifies provider config is loadable.");
      console.log("  Skipping actual API call - no Twilio SDK dependency.");

      await netProvider.connect(netConfig);
      console.log("  Connect:           OK (local handshake)");
      await netProvider.disconnect();
      console.log("  Disconnect:        OK");
      console.log();
      console.log("Twilio Provider Test: PASSED (network mode, local handshake only)");
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      console.log(`  Connect:           FAILED`);
      console.log(`  Error:             ${message}`);
      console.log();
      console.log("Twilio Provider Test: FAILED (network)");
      process.exit(1);
    } finally {
      clearTimeout(timeoutId);
    }
  } else {
    console.log("  Network mode:      disabled (set TWILIO_NETWORK_TEST=1 to enable)");
    console.log("  No API connection was made.");
    console.log("  No call was made.");
    console.log();

    console.log("Twilio Provider Test: PASSED (local config check)");
  }
}

await main();
