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

const json = (status: number, body: unknown) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
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
    headers: { "Content-Type": "application/json" },
  });
});
