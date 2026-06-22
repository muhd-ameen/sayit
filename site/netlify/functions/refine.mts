import type { Config, Context } from "@netlify/functions";
import { getStore } from "@netlify/blobs";

const ANTHROPIC_URL = "https://api.anthropic.com/v1/messages";
const MODEL = "claude-haiku-4-5";
const MAX_TOKENS = 512;

// Abuse guards
const MAX_FIELD_CHARS = 8_000; // generous cap for a single refinement
const RATE_LIMIT_PER_MIN = 20; // refinements per IP per minute

function env(name: string): string | undefined {
  // Netlify.env is the modern accessor; fall back to process.env for local tooling.
  return (globalThis as any).Netlify?.env?.get?.(name) ?? process.env[name];
}

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

// Coarse per-IP, per-minute rate limit backed by Netlify Blobs.
// Eventually consistent — good enough to blunt abuse, not a hard quota.
async function isRateLimited(ip: string): Promise<boolean> {
  try {
    const store = getStore("refine-rate-limit");
    const bucket = Math.floor(Date.now() / 60_000); // current minute
    const key = `${ip}:${bucket}`;
    const current = Number((await store.get(key)) ?? 0);
    if (current >= RATE_LIMIT_PER_MIN) return true;
    await store.set(key, String(current + 1));
    return false;
  } catch {
    // If the store is unavailable, fail open rather than blocking real users.
    return false;
  }
}

export default async (req: Request, context: Context): Promise<Response> => {
  // 1. App token check — not a real secret, but ours to rotate/revoke.
  const expected = env("SAYIT_APP_TOKEN");
  if (!expected || req.headers.get("x-sayit-app") !== expected) {
    return json(401, { error: "unauthorized" });
  }

  // 2. Rate limit per client IP.
  const ip = context.ip || "unknown";
  if (await isRateLimited(ip)) {
    return json(429, { error: "rate_limited" });
  }

  // 3. Parse + validate body.
  let payload: { system?: unknown; prompt?: unknown };
  try {
    payload = await req.json();
  } catch {
    return json(400, { error: "invalid_json" });
  }
  const { system, prompt } = payload;
  if (
    typeof system !== "string" ||
    typeof prompt !== "string" ||
    system.length === 0 ||
    prompt.length === 0 ||
    system.length > MAX_FIELD_CHARS ||
    prompt.length > MAX_FIELD_CHARS
  ) {
    return json(400, { error: "invalid_body" });
  }

  // 4. Forward to Anthropic with pinned model/limits (cost ceiling per call).
  const apiKey = env("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json(500, { error: "server_misconfigured" });
  }

  let upstream: Response;
  try {
    upstream = await fetch(ANTHROPIC_URL, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: MAX_TOKENS,
        stream: true,
        system,
        messages: [{ role: "user", content: prompt }],
      }),
    });
  } catch (e) {
    return json(502, { error: "upstream_unreachable" });
  }

  if (!upstream.ok || !upstream.body) {
    const detail = await upstream.text().catch(() => "");
    return json(upstream.status || 502, { error: "upstream_error", detail: detail.slice(0, 500) });
  }

  // 5. Pipe the SSE stream straight through to the app, unchanged.
  return new Response(upstream.body, {
    status: 200,
    headers: {
      "content-type": "text/event-stream",
      "cache-control": "no-cache",
    },
  });
};

export const config: Config = {
  path: "/api/refine",
  method: "POST",
};
