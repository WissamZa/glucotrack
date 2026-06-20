import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import type { Language, ThemeStyle, DiabetesType, GlucoseUnit } from "@/lib/types";

const VALID_LANGS: Language[] = ["ar", "en"];
const VALID_THEMES: ThemeStyle[] = ["classic", "modern", "elder"];
const VALID_DTYPES: DiabetesType[] = ["type1", "type2", "gestational"];
const VALID_UNITS: GlucoseUnit[] = ["mg_dL", "mmol_L"];

// GET /api/settings — returns the singleton settings row (creates default if missing)
export async function GET() {
  try {
    let settings = await db.settings.findUnique({ where: { id: 1 } });
    if (!settings) {
      settings = await db.settings.create({ data: { id: 1 } });
    }
    return NextResponse.json({ settings });
  } catch (e) {
    console.error("GET /api/settings error:", e);
    return NextResponse.json({ error: "failed_to_fetch" }, { status: 500 });
  }
}

// PUT /api/settings — update the singleton settings row
export async function PUT(req: NextRequest) {
  try {
    const body = await req.json();
    const data: Record<string, unknown> = {};

    if (typeof body.language === "string" && VALID_LANGS.includes(body.language)) {
      data.language = body.language;
    }
    if (typeof body.theme === "string" && VALID_THEMES.includes(body.theme)) {
      data.theme = body.theme;
    }
    if (typeof body.diabetesType === "string" && VALID_DTYPES.includes(body.diabetesType)) {
      data.diabetesType = body.diabetesType;
    }
    if (typeof body.targetMin === "number") {
      data.targetMin = Math.max(40, Math.min(150, body.targetMin));
    }
    if (typeof body.targetMax === "number") {
      data.targetMax = Math.max(120, Math.min(300, body.targetMax));
    }
    if (typeof body.unit === "string" && VALID_UNITS.includes(body.unit)) {
      data.unit = body.unit;
    }
    if (typeof body.userName === "string") {
      data.userName = body.userName.slice(0, 50);
    }
    if (typeof body.onboarded === "boolean") {
      data.onboarded = body.onboarded;
    }

    // Upsert to be safe (settings row should always exist after GET)
    const settings = await db.settings.upsert({
      where: { id: 1 },
      update: data,
      create: { id: 1, ...data },
    });

    return NextResponse.json({ settings });
  } catch (e) {
    console.error("PUT /api/settings error:", e);
    return NextResponse.json({ error: "failed_to_update" }, { status: 500 });
  }
}
