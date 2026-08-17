import { createRemoteJWKSet, jwtVerify, SignJWT } from "jose";

const appleKeys = createRemoteJWKSet(new URL("https://appleid.apple.com/auth/keys"));

export interface SessionPrincipal {
  readonly userId: string;
}

export async function exchangeAppleToken(identityToken: string, env: Env): Promise<string> {
  const { payload } = await jwtVerify(identityToken, appleKeys, {
    issuer: "https://appleid.apple.com",
    audience: env.APPLE_CLIENT_ID,
  });
  if (!payload.sub) throw new Error("Apple token has no subject");
  return new SignJWT({ scope: "user" })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(payload.sub)
    .setIssuer("tally-edge")
    .setAudience("tally-ios")
    .setIssuedAt()
    .setExpirationTime("30d")
    .sign(new TextEncoder().encode(env.SESSION_SIGNING_SECRET));
}

export async function authenticate(request: Request, env: Env): Promise<SessionPrincipal | null> {
  const header = request.headers.get("authorization");
  if (!header?.startsWith("Bearer ")) return null;
  try {
    const { payload } = await jwtVerify(header.slice(7), new TextEncoder().encode(env.SESSION_SIGNING_SECRET), {
      issuer: "tally-edge",
      audience: "tally-ios",
    });
    return payload.sub ? { userId: payload.sub } : null;
  } catch {
    return null;
  }
}

