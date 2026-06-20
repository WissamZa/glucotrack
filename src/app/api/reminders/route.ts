import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import type { ReadingType } from "@/lib/types";

const VALID_TYPES: ReadingType[] = [
  "fasting",
  "before_meal",
  "after_meal",
  "before_sleep",
  "after_exercise",
  "other",
];

// GET /api/reminders
export async function GET() {
  try {
    const reminders = await db.reminder.findMany({
      orderBy: { time: "asc" },
    });
    return NextResponse.json({ reminders });
  } catch (e) {
    console.error("GET /api/reminders error:", e);
    return NextResponse.json({ error: "failed_to_fetch" }, { status: 500 });
  }
}

// POST /api/reminders
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { time, label, type, enabled } = body ?? {};

    if (!time || !/^\d{2}:\d{2}$/.test(time)) {
      return NextResponse.json({ error: "invalid_time" }, { status: 400 });
    }
    if (!VALID_TYPES.includes(type as ReadingType)) {
      return NextResponse.json({ error: "invalid_type" }, { status: 400 });
    }

    const reminder = await db.reminder.create({
      data: {
        time,
        label: label || type,
        type,
        enabled: enabled !== false,
      },
    });

    return NextResponse.json({ reminder }, { status: 201 });
  } catch (e) {
    console.error("POST /api/reminders error:", e);
    return NextResponse.json({ error: "failed_to_create" }, { status: 500 });
  }
}
