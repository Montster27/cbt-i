import { NextResponse } from "next/server";

const WHOOP_TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token";
const ALLOWED_REDIRECT_URI = "cbti://oauth/callback";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request) {
  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "invalid_json" }, { status: 400 });
  }

  const code = body?.code;
  if (typeof code !== "string" || code.length === 0) {
    return NextResponse.json({ error: "missing_code" }, { status: 400 });
  }

  // Optionally accept redirect_uri from the client but only honor it if it matches
  // the registered native callback. Prevents the proxy from being used as a generic
  // OAuth exchange for arbitrary apps.
  const redirectURI = typeof body?.redirect_uri === "string" ? body.redirect_uri : ALLOWED_REDIRECT_URI;
  if (redirectURI !== ALLOWED_REDIRECT_URI) {
    return NextResponse.json({ error: "redirect_uri_not_allowed" }, { status: 400 });
  }

  const clientID = process.env.WHOOP_CLIENT_ID;
  const clientSecret = process.env.WHOOP_CLIENT_SECRET;
  if (!clientID || !clientSecret) {
    return NextResponse.json({ error: "server_not_configured" }, { status: 500 });
  }

  const form = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    redirect_uri: redirectURI,
    client_id: clientID,
    client_secret: clientSecret,
  });

  let whoopResponse;
  try {
    whoopResponse = await fetch(WHOOP_TOKEN_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "application/json",
      },
      body: form.toString(),
    });
  } catch (err) {
    console.error("[whoop/exchange] network error:", err);
    return NextResponse.json(
      { error: "whoop_unreachable", message: String(err) },
      { status: 502 }
    );
  }

  const text = await whoopResponse.text();
  if (!whoopResponse.ok) {
    console.error("[whoop/exchange] whoop returned", whoopResponse.status, text.slice(0, 200));
    return NextResponse.json(
      { error: "whoop_error", status: whoopResponse.status, body: text },
      { status: whoopResponse.status }
    );
  }

  return new NextResponse(text, {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}
