import { NextResponse } from "next/server";
import { db } from "@/lib/db";

// GET /api/sync/status — current sync state
export async function GET() {
  try {
    let state = await db.syncState.findUnique({ where: { id: 1 } });
    if (!state) {
      state = await db.syncState.create({ data: { id: 1 } });
    }

    // Don't expose tokens to the client
    return NextResponse.json({
      state: {
        id: state.id,
        provider: state.provider,
        connected: state.connected,
        accountEmail: state.accountEmail,
        lastSyncAt: state.lastSyncAt,
        lastSyncStatus: state.lastSyncStatus,
        lastSyncError: state.lastSyncError,
        driveFileId: state.driveFileId,
      },
    });
  } catch (e) {
    console.error("GET /api/sync/status error:", e);
    return NextResponse.json({ error: "failed_to_fetch" }, { status: 500 });
  }
}
