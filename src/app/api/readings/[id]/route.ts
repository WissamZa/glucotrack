import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";

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
