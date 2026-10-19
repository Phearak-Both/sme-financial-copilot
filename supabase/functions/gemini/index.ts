// Gemini proxy for the SME Financial Copilot app.
//
// The app sends { model, request } with the signed-in user's access token;
// this function checks the token, adds the Gemini API key (a function
// secret, never shipped in the app) and forwards the request to Google.
// Gemini's status code and body are passed back unchanged, so the app's
// quota fallback and JSON parsing work the same as calling Gemini directly.
//
// Deploy: supabase functions deploy gemini
// Secret: supabase secrets set GEMINI_API_KEY=...

import { createClient } from "npm:@supabase/supabase-js@2";

// Only models the app uses; stops the key being used for anything else.
const ALLOWED_MODELS = new Set([
  "gemini-flash-lite-latest",
  "gemini-flash-latest",
  "gemini-3.5-flash",
]);

// A receipt photo (~1600 px JPEG) base64-encoded stays well under this.
const MAX_BODY_BYTES = 8 * 1024 * 1024;

// Browsers only call another site's function if it allows their origin:
// the web app on Netlify (and its deploy previews) and local testing. The
// phone and desktop apps send no Origin and don't need this.
const ALLOWED_ORIGINS = [
  /^https:\/\/sme-copilot\.netlify\.app$/,
  /^https:\/\/[a-z0-9-]+--sme-copilot\.netlify\.app$/,
  /^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/,
];

const corsHeaders = (origin: string | null): Record<string, string> =>
  origin && ALLOWED_ORIGINS.some((re) => re.test(origin))
    ? {
      "Access-Control-Allow-Origin": origin,
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Access-Control-Allow-Headers":
        "authorization, apikey, content-type, x-client-info",
      "Access-Control-Max-Age": "86400",
      "Vary": "Origin",
    }
    : {};

Deno.serve(async (req) => {
  const cors = corsHeaders(req.headers.get("Origin"));
  const json = (status: number, body: unknown) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...cors, "Content-Type": "application/json" },
    });

  // The browser's permission check before the real request.
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }
  if (req.method !== "POST") return json(405, { error: "POST only" });

  // Signed-in users only. The project uses asymmetric JWT signing keys, so
  // the token is checked here rather than with the platform's verify_jwt.
  const token = req.headers.get("Authorization")?.replace(/^Bearer\s+/i, "");
  if (!token) return json(401, { error: "Sign in required" });
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
  );
  const { data, error } = await supabase.auth.getUser(token);
  if (error || !data.user) return json(401, { error: "Sign in required" });

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return json(500, { error: "GEMINI_API_KEY is not set" });

  const raw = await req.text();
  if (raw.length > MAX_BODY_BYTES) {
    return json(413, { error: "Request too large" });
  }
  let payload: { model?: string; request?: unknown };
  try {
    payload = JSON.parse(raw);
  } catch {
    return json(400, { error: "Body must be JSON" });
  }
  const model = payload.model ?? "";
  if (!ALLOWED_MODELS.has(model) || typeof payload.request !== "object") {
    return json(400, { error: "Unknown model or missing request" });
  }

  const upstream = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify(payload.request),
    },
  );
  return new Response(upstream.body, {
    status: upstream.status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
