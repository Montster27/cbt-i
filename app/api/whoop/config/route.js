import { NextResponse } from "next/server";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Returns the public bits of the Whoop OAuth configuration so the native app
// doesn't need to ship a client ID. The client ID is not a secret — it appears
// in every authorization URL — but centralizing it here means rotating Whoop
// apps requires no app rebuild.
export async function GET() {
  const clientID = process.env.WHOOP_CLIENT_ID;
  if (!clientID) {
    console.error("[whoop/config] WHOOP_CLIENT_ID not set");
    return NextResponse.json({ error: "server_not_configured" }, { status: 500 });
  }
  return NextResponse.json({
    client_id: clientID,
    redirect_uri: "cbti://oauth/callback",
    scopes: "read:sleep read:cycles read:recovery offline",
  });
}
