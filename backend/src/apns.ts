import { importPKCS8, SignJWT } from "jose";

let cached: { token: string; expires: number } | undefined;

async function providerToken(env: Env): Promise<string> {
  if (cached && cached.expires > Date.now()) return cached.token;
  const key = await importPKCS8(env.APNS_PRIVATE_KEY.replace(/\\n/g, "\n"), "ES256");
  const token = await new SignJWT({}).setProtectedHeader({ alg: "ES256", kid: env.APNS_KEY_ID })
    .setIssuer(env.APNS_TEAM_ID).setIssuedAt().sign(key);
  cached = { token, expires: Date.now() + 50 * 60 * 1000 };
  return token;
}

export async function sendPriorityPush(env: Env, device: { token: string; environment: string }, title: string, body: string): Promise<void> {
  const host = device.environment === "production" ? "api.push.apple.com" : "api.sandbox.push.apple.com";
  const response = await fetch(`https://${host}/3/device/${device.token}`, {
    method: "POST",
    headers: { authorization: `bearer ${await providerToken(env)}`, "apns-topic": env.APNS_BUNDLE_ID, "apns-push-type": "alert", "apns-priority": "10" },
    body: JSON.stringify({ aps: { alert: { title, body }, sound: "default" } }),
  });
  if (!response.ok && response.status !== 410) throw new Error(`APNs returned ${response.status}`);
}
