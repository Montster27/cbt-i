import { NextResponse } from "next/server";

const WHOOP_TOKEN_URL = "https://api.prod.whoop.com/oauth/oauth2/token";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export async function POST(request) {
  let body;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "invalid_json" }, { status: 400 });
  }

  const refreshToken = body?.refresh_token;
  if (typeof refreshToken !== "string" || refreshToken.length === 0) {
    return NextResponse.json({ error: "missing_refresh_token" }, { status: 400 });
  }

  const clientID = process.env.WHOOP_CLIENT_ID;
  const clientSecret = process.env.WHOOP_CLIENT_SECRET;
  if (!clientID || !clientSecret) {
    return NextResponse.json({ error: "server_not_configured" }, { status: 500 });
  }

  const form = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: refreshToken,
    client_id: clientID,
    client_secret: clientSecret,
    scope: "offline",
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
    console.error("[whoop/refresh] network error:", err);
    return NextResponse.json(
      { error: "whoop_unreachable", message: String(err) },
      { status: 502 }
    );
  }

  const text = await whoopResponse.text();
  if (!whoopResponse.ok) {
    console.error("[whoop/refresh] whoop returned", whoopResponse.status, text.slice(0, 200));
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
