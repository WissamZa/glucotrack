import type { ThemeStyle, ReadingStatus } from "./types";

export interface ThemeColors {
  // Backgrounds
  bg: string;            // page background
  surface: string;       // card surface
  surfaceAlt: string;    // alt card surface
  // Text
  text: string;          // primary text
  textMuted: string;     // secondary text
  // Brand
  primary: string;       // brand color
  primaryText: string;   // text on primary
  // Status
  low: string;
  inRange: string;
  high: string;
  critical: string;
  // Borders
  border: string;
  // Typography scale (rem)
  fontSizeSm: string;
  fontSizeBase: string;
  fontSizeLg: string;
  fontSizeXl: string;
  fontSize2xl: string;
  // Radius
  radius: string;
  // Spacing scale
  padding: string;
}

export const themes: Record<ThemeStyle, ThemeColors> = {
  // ===== Classic Medical =====
  classic: {
    bg: "bg-slate-50",
    surface: "bg-white",
    surfaceAlt: "bg-slate-50",
    text: "text-slate-900",
    textMuted: "text-slate-500",
    primary: "bg-teal-600",
    primaryText: "text-white",
    low: "bg-amber-100 text-amber-700 border-amber-200",
    inRange: "bg-emerald-100 text-emerald-700 border-emerald-200",
    high: "bg-orange-100 text-orange-700 border-orange-200",
    critical: "bg-red-100 text-red-700 border-red-200",
    border: "border-slate-200",
    fontSizeSm: "text-sm",
    fontSizeBase: "text-base",
    fontSizeLg: "text-lg",
    fontSizeXl: "text-xl",
    fontSize2xl: "text-2xl",
    radius: "rounded-2xl",
    padding: "p-4",
  },

  // ===== Modern Youth =====
  modern: {
    bg: "bg-[#0B0F1A]",
    surface: "bg-white/5 backdrop-blur-xl border border-white/10",
    surfaceAlt: "bg-white/[0.03]",
    text: "text-white",
    textMuted: "text-white/60",
    primary: "bg-gradient-to-br from-fuchsia-500 to-cyan-400",
    primaryText: "text-white",
    low: "bg-amber-500/20 text-amber-300 border-amber-400/30",
    inRange: "bg-emerald-500/20 text-emerald-300 border-emerald-400/30",
    high: "bg-orange-500/20 text-orange-300 border-orange-400/30",
    critical: "bg-red-500/25 text-red-300 border-red-400/40",
    border: "border-white/10",
    fontSizeSm: "text-sm",
    fontSizeBase: "text-base",
    fontSizeLg: "text-lg",
    fontSizeXl: "text-xl",
    fontSize2xl: "text-2xl",
    radius: "rounded-3xl",
    padding: "p-4",
  },

  // ===== Elder-Friendly =====
  elder: {
    bg: "bg-white",
    surface: "bg-slate-50 border-2 border-slate-900",
    surfaceAlt: "bg-white border-2 border-slate-300",
    text: "text-slate-900",
    textMuted: "text-slate-700",
    primary: "bg-slate-900",
    primaryText: "text-white",
    low: "bg-amber-200 text-amber-900 border-2 border-amber-700",
    inRange: "bg-emerald-200 text-emerald-900 border-2 border-emerald-700",
    high: "bg-orange-200 text-orange-900 border-2 border-orange-700",
    critical: "bg-red-300 text-red-900 border-2 border-red-800",
    border: "border-2 border-slate-900",
    fontSizeSm: "text-lg",
    fontSizeBase: "text-xl",
    fontSizeLg: "text-2xl",
    fontSizeXl: "text-3xl",
    fontSize2xl: "text-4xl",
    radius: "rounded-2xl",
    padding: "p-6",
  },
};

export function statusClasses(theme: ThemeStyle, status: ReadingStatus): string {
  const t = themes[theme];
  if (status === "low") return t.low;
  if (status === "in_range") return t.inRange;
  if (status === "high") return t.high;
  return t.critical; // critical_low & critical_high
}

export function statusDotColor(status: ReadingStatus): string {
  if (status === "low") return "bg-amber-500";
  if (status === "in_range") return "bg-emerald-500";
  if (status === "high") return "bg-orange-500";
  return "bg-red-500";
}

export function chartLineColor(theme: ThemeStyle): string {
  if (theme === "modern") return "#22d3ee";
  if (theme === "elder") return "#0f172a";
  return "#0d9488";
}

export function chartFillColor(theme: ThemeStyle): string {
  if (theme === "modern") return "rgba(34, 211, 238, 0.2)";
  if (theme === "elder") return "rgba(15, 23, 42, 0.15)";
  return "rgba(13, 148, 136, 0.15)";
}

export function chartTextColor(theme: ThemeStyle): string {
  if (theme === "modern") return "rgba(255,255,255,0.7)";
  if (theme === "elder") return "#0f172a";
  return "#475569";
}

export function chartGridColor(theme: ThemeStyle): string {
  if (theme === "modern") return "rgba(255,255,255,0.08)";
  if (theme === "elder") return "#e2e8f0";
  return "#e2e8f0";
}
