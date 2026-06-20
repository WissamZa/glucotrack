import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";

// PATCH /api/reminders/[id] — toggle enabled, update fields
export async function PATCH(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    const body = await req.json();
    const { enabled, time, label, type } = body ?? {};

    const data: Record<string, unknown> = {};
    if (typeof enabled === "boolean") data.enabled = enabled;
    if (typeof time === "string") data.time = time;
    if (typeof label === "string") data.label = label;
    if (typeof type === "string") data.type = type;

    const updated = await db.reminder.update({
      where: { id },
      data,
    });

    return NextResponse.json({ reminder: updated });
  } catch (e) {
    console.error("PATCH /api/reminders/[id] error:", e);
    return NextResponse.json({ error: "failed_to_update" }, { status: 500 });
  }
}

// DELETE /api/reminders/[id]
export async function DELETE(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  try {
    const { id } = await params;
    await db.reminder.delete({ where: { id } });
    return NextResponse.json({ ok: true });
  } catch (e) {
    console.error("DELETE /api/reminders/[id] error:", e);
    return NextResponse.json({ error: "failed_to_delete" }, { status: 500 });
  }
}
