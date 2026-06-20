import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { seedReadings, seedReminders, defaultSettings } from "@/lib/seed";

// POST /api/seed — populate DB with demo data on first launch (idempotent)
export async function POST() {
  try {
    const count = await db.reading.count();
    if (count > 0) {
      return NextResponse.json({ ok: true, message: "already_seeded", count });
    }

    // Insert seed readings
    await db.reading.createMany({
      data: seedReadings.map((r) => ({
        id: r.id,
        value: r.value,
        type: r.type,
        timestamp: new Date(r.timestamp),
        notes: r.notes || null,
        carbs: r.carbs || null,
        insulin: r.insulin || null,
      })),
    });

    // Insert seed reminders
    await db.reminder.createMany({
      data: seedReminders.map((r) => ({
        id: r.id,
        time: r.time,
        label: r.label,
        type: r.type,
        enabled: r.enabled,
      })),
    });

    // Ensure default settings row exists
    await db.settings.upsert({
      where: { id: 1 },
      update: {},
      create: {
        id: 1,
        language: defaultSettings.language,
        theme: defaultSettings.theme,
        diabetesType: defaultSettings.diabetesType,
        targetMin: defaultSettings.targetMin,
        targetMax: defaultSettings.targetMax,
        unit: defaultSettings.unit,
        userName: defaultSettings.userName,
        onboarded: false,
      },
    });

    return NextResponse.json({ ok: true, message: "seeded", count: seedReadings.length });
  } catch (e) {
    console.error("POST /api/seed error:", e);
    return NextResponse.json({ error: "failed_to_seed" }, { status: 500 });
  }
}
