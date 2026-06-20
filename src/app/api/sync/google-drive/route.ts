import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { uploadBackup, getUserEmail, type DriveBackup } from "@/lib/google-drive";

// POST /api/sync/google-drive
// Body: { action: "connect" | "upload" | "disconnect", accessToken?: string }
//   - connect: store access token + email, mark connected
//   - upload: build backup from DB, upload to Drive
//   - disconnect: clear all sync state
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { action, accessToken } = body ?? {};

    // ===== CONNECT =====
    if (action === "connect") {
      if (!accessToken || typeof accessToken !== "string") {
        return NextResponse.json({ error: "missing_access_token" }, { status: 400 });
      }

      // Verify token by fetching user email
      let email = "";
      try {
        email = await getUserEmail(accessToken);
      } catch (e) {
        console.error("getUserEmail failed:", e);
        return NextResponse.json(
          { error: "invalid_access_token" },
          { status: 401 },
        );
      }

      // Calculate expiry (1 hour from now — Google access tokens last 1h)
      const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

      const state = await db.syncState.upsert({
        where: { id: 1 },
        update: {
          provider: "google_drive",
          connected: true,
          accountEmail: email,
          accessToken,
          expiresAt,
          updatedAt: new Date(),
        },
        create: {
          id: 1,
          provider: "google_drive",
          connected: true,
          accountEmail: email,
          accessToken,
          expiresAt,
        },
      });

      return NextResponse.json({
        state: {
          connected: state.connected,
          accountEmail: state.accountEmail,
          provider: state.provider,
        },
      });
    }

    // ===== UPLOAD =====
    if (action === "upload") {
      const syncState = await db.syncState.findUnique({ where: { id: 1 } });
      if (!syncState?.connected || !syncState.accessToken) {
        return NextResponse.json({ error: "not_connected" }, { status: 400 });
      }

      // Mark sync in progress
      await db.syncState.update({
        where: { id: 1 },
        data: {
          lastSyncStatus: "in_progress",
          lastSyncError: null,
          updatedAt: new Date(),
        },
      });

      try {
        // Build backup payload from DB
        const [readings, reminders, settings] = await Promise.all([
          db.reading.findMany({ orderBy: { timestamp: "desc" } }),
          db.reminder.findMany({ orderBy: { time: "asc" } }),
          db.settings.findUnique({ where: { id: 1 } }),
        ]);

        const backup: DriveBackup = {
          app: "glucotrack",
          version: 1,
          exportedAt: new Date().toISOString(),
          readings: readings.map((r) => ({
            id: r.id,
            value: r.value,
            type: r.type,
            timestamp: r.timestamp.toISOString(),
            notes: r.notes,
            carbs: r.carbs,
            insulin: r.insulin,
          })),
          reminders: reminders.map((r) => ({
            id: r.id,
            time: r.time,
            label: r.label,
            type: r.type,
            enabled: r.enabled,
          })),
          settings: settings
            ? {
                language: settings.language,
                theme: settings.theme,
                diabetesType: settings.diabetesType,
                targetMin: settings.targetMin,
                targetMax: settings.targetMax,
                unit: settings.unit,
                userName: settings.userName,
              }
            : null,
        };

        const result = await uploadBackup(syncState.accessToken, backup);

        await db.syncState.update({
          where: { id: 1 },
          data: {
            lastSyncAt: new Date(),
            lastSyncStatus: "success",
            lastSyncError: null,
            driveFileId: result.fileId,
            updatedAt: new Date(),
          },
        });

        return NextResponse.json({
          ok: true,
          fileId: result.fileId,
          created: result.created,
          counts: {
            readings: backup.readings.length,
            reminders: backup.reminders.length,
          },
        });
      } catch (e) {
        const msg = e instanceof Error ? e.message : "unknown_error";
        await db.syncState.update({
          where: { id: 1 },
          data: {
            lastSyncStatus: "failed",
            lastSyncError: msg,
            updatedAt: new Date(),
          },
        });
        return NextResponse.json({ error: msg }, { status: 500 });
      }
    }

    // ===== DISCONNECT =====
    if (action === "disconnect") {
      await db.syncState.update({
        where: { id: 1 },
        data: {
          provider: "",
          connected: false,
          accountEmail: null,
          accessToken: null,
          refreshToken: null,
          expiresAt: null,
          driveFileId: null,
          updatedAt: new Date(),
        },
      });

      return NextResponse.json({ ok: true });
    }

    return NextResponse.json({ error: "invalid_action" }, { status: 400 });
  } catch (e) {
    console.error("POST /api/sync/google-drive error:", e);
    return NextResponse.json({ error: "failed_to_sync" }, { status: 500 });
  }
}

// GET /api/sync/google-drive?action=download — pull remote backup and merge
export async function GET(req: NextRequest) {
  try {
    const url = new URL(req.url);
    const action = url.searchParams.get("action");
    if (action !== "download") {
      return NextResponse.json({ error: "invalid_action" }, { status: 400 });
    }

    const syncState = await db.syncState.findUnique({ where: { id: 1 } });
    if (!syncState?.connected || !syncState.accessToken) {
      return NextResponse.json({ error: "not_connected" }, { status: 400 });
    }

    // Mark in progress
    await db.syncState.update({
      where: { id: 1 },
      data: { lastSyncStatus: "in_progress", lastSyncError: null, updatedAt: new Date() },
    });

    // Inline the download logic to avoid an extra import cycle
    const fileId = syncState.driveFileId;
    if (!fileId) {
      await db.syncState.update({
        where: { id: 1 },
        data: { lastSyncStatus: "failed", lastSyncError: "no_file_id", updatedAt: new Date() },
      });
      return NextResponse.json({ error: "no_file_id" }, { status: 400 });
    }

    const contentRes = await fetch(
      `https://www.googleapis.com/drive/v3/files/${fileId}?alt=media`,
      { headers: { Authorization: `Bearer ${syncState.accessToken}` } },
    );

    if (!contentRes.ok) {
      const errText = await contentRes.text();
      await db.syncState.update({
        where: { id: 1 },
        data: { lastSyncStatus: "failed", lastSyncError: `download_${contentRes.status}`, updatedAt: new Date() },
      });
      return NextResponse.json({ error: `download_failed: ${errText}` }, { status: 502 });
    }

    const text = await contentRes.text();
    let backup: {
      app: string;
      readings: Array<{ id: string; value: number; type: string; timestamp: string; notes?: string | null; carbs?: number | null; insulin?: number | null }>;
      reminders: Array<{ id: string; time: string; label: string; type: string; enabled: boolean }>;
      settings?: Record<string, unknown> | null;
    };
    try {
      backup = JSON.parse(text);
    } catch {
      await db.syncState.update({
        where: { id: 1 },
        data: { lastSyncStatus: "failed", lastSyncError: "invalid_json", updatedAt: new Date() },
      });
      return NextResponse.json({ error: "invalid_json" }, { status: 502 });
    }

    if (backup.app !== "glucotrack") {
      await db.syncState.update({
        where: { id: 1 },
        data: { lastSyncStatus: "failed", lastSyncError: "invalid_app", updatedAt: new Date() },
      });
      return NextResponse.json({ error: "invalid_backup_app" }, { status: 502 });
    }

    // === Merge strategy ===
    // For readings: upsert by ID (remote wins on conflict).
    // For reminders: upsert by ID (remote wins).
    // For settings: skip — local settings always win to avoid wiping user prefs.
    let mergedReadings = 0;
    let mergedReminders = 0;

    for (const r of backup.readings) {
      await db.reading.upsert({
        where: { id: r.id },
        update: {
          value: r.value,
          type: r.type,
          timestamp: new Date(r.timestamp),
          notes: r.notes || null,
          carbs: r.carbs ?? null,
          insulin: r.insulin ?? null,
        },
        create: {
          id: r.id,
          value: r.value,
          type: r.type,
          timestamp: new Date(r.timestamp),
          notes: r.notes || null,
          carbs: r.carbs ?? null,
          insulin: r.insulin ?? null,
        },
      });
      mergedReadings++;
    }

    for (const r of backup.reminders) {
      await db.reminder.upsert({
        where: { id: r.id },
        update: {
          time: r.time,
          label: r.label,
          type: r.type,
          enabled: r.enabled,
        },
        create: {
          id: r.id,
          time: r.time,
          label: r.label,
          type: r.type,
          enabled: r.enabled,
        },
      });
      mergedReminders++;
    }

    await db.syncState.update({
      where: { id: 1 },
      data: {
        lastSyncAt: new Date(),
        lastSyncStatus: "success",
        lastSyncError: null,
        updatedAt: new Date(),
      },
    });

    return NextResponse.json({
      ok: true,
      merged: { readings: mergedReadings, reminders: mergedReminders },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : "unknown_error";
    console.error("GET /api/sync/google-drive error:", e);
    await db.syncState.update({
      where: { id: 1 },
      data: { lastSyncStatus: "failed", lastSyncError: msg, updatedAt: new Date() },
    });
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
