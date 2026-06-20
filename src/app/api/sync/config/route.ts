import { NextResponse } from "next/server";

// GET /api/sync/config — exposes non-secret sync config to the client
export async function GET() {
  return NextResponse.json({
    googleClientId: process.env.GOOGLE_CLIENT_ID || "",
    // The Drive scope we request: appDataFolder only (hidden folder scoped to this app)
    scope: "https://www.googleapis.com/auth/drive.appdata",
  });
}
