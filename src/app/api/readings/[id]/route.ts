import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";

const VALID_TYPES = [
  "fasting",
  "before_meal",
  "after_meal",
  "before_sleep",
  "after_exercise",
  "other",
];

// PATCH /api/readings/[id] — update an existing reading
export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await req.json();

    const data: Record<string, unknown> = {};

    if (typeof body.value === "number") {
      if (body.value < 20 || body.value > 600) {
        return NextResponse.json({ error: "invalid_value" }, { status: 400 });
      }
      data.value = body.value;
    }
    if (typeof body.type === "string") {
      if (!VALID_TYPES.includes(body.type)) {
        return NextResponse.json({ error: "invalid_type" }, { status: 400 });
      }
      data.type = body.type;
    }
    if (typeof body.timestamp === "number" || typeof body.timestamp === "string") {
      const ts = new Date(body.timestamp);
      if (isNaN(ts.getTime())) {
        return NextResponse.json({ error: "invalid_timestamp" }, { status: 400 });
      }
      data.timestamp = ts;
    }
    if (typeof body.notes === "string") data.notes = body.notes || null;
    if (typeof body.carbs === "number") data.carbs = body.carbs;
    if (typeof body.insulin === "number") data.insulin = body.insulin;

    const updated = await db.reading.update({
      where: { id },
      data,
    });

    return NextResponse.json({ reading: updated });
  } catch (e) {
    console.error("PATCH /api/readings/[id] error:", e);
    return NextResponse.json({ error: "failed_to_update" }, { status: 500 });
  }
}

// DELETE /api/readings/[id]
export async function DELETE(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await db.reading.delete({ where: { id } });
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("DELETE /api/readings/[id] error:", e);
    return NextResponse.json({ error: "failed_to_delete" }, { status: 500 });
  }
}
