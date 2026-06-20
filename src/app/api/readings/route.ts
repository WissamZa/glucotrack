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

// GET /api/readings — list all readings, sorted by timestamp DESC
export async function GET() {
  try {
    const readings = await db.reading.findMany({
      orderBy: { timestamp: "desc" },
    });
    return NextResponse.json({ readings });
  } catch (e) {
    console.error("GET /api/readings error:", e);
    return NextResponse.json({ error: "failed_to_fetch" }, { status: 500 });
  }
}

// POST /api/readings — create a new reading
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { value, type, timestamp, notes, carbs, insulin } = body ?? {};

    if (typeof value !== "number" || value < 20 || value > 600) {
      return NextResponse.json({ error: "invalid_value" }, { status: 400 });
    }
    if (!VALID_TYPES.includes(type as ReadingType)) {
      return NextResponse.json({ error: "invalid_type" }, { status: 400 });
    }

    const ts = new Date(timestamp);
    if (isNaN(ts.getTime())) {
      return NextResponse.json({ error: "invalid_timestamp" }, { status: 400 });
    }

    const reading = await db.reading.create({
      data: {
        value,
        type,
        timestamp: ts,
        notes: notes || null,
        carbs: typeof carbs === "number" ? carbs : null,
        insulin: typeof insulin === "number" ? insulin : null,
      },
    });

    return NextResponse.json({ reading }, { status: 201 });
  } catch (e) {
    console.error("POST /api/readings error:", e);
    return NextResponse.json({ error: "failed_to_create" }, { status: 500 });
  }
}
