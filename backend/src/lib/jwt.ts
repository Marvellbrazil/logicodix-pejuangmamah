import { SignJWT, jwtVerify } from 'jose';

export type SessionClaims = {
  sub: string;
  role: 'worker' | 'employer';
};

const ISSUER = 'kerjaqueue';
const AUDIENCE = 'kerjaqueue-app';
const TTL = '30d';

function key(secret: string): Uint8Array {
  return new TextEncoder().encode(secret);
}

export async function signSession(
  claims: SessionClaims,
  secret: string,
): Promise<string> {
  return new SignJWT({ role: claims.role })
    .setProtectedHeader({ alg: 'HS256', typ: 'JWT' })
    .setSubject(claims.sub)
    .setIssuer(ISSUER)
    .setAudience(AUDIENCE)
    .setIssuedAt()
    .setExpirationTime(TTL)
    .sign(key(secret));
}

export async function verifySession(
  token: string,
  secret: string,
): Promise<SessionClaims | null> {
  try {
    const { payload } = await jwtVerify(token, key(secret), {
      issuer: ISSUER,
      audience: AUDIENCE,
    });
    const role = payload.role;
    if (typeof payload.sub !== 'string') return null;
    if (role !== 'worker' && role !== 'employer') return null;
    return { sub: payload.sub, role };
  } catch {
    return null;
  }
}
