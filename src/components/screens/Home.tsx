"use client";

import { useAppStore } from "@/lib/store";
import { themes, statusClasses, statusDotColor } from "@/lib/themes";
import { t, readingTypeLabel, statusLabel } from "@/lib/i18n";
import { getStatus } from "@/lib/types";
import type { Reading } from "@/lib/types";
import { motion } from "framer-motion";
import { Droplet, TrendingUp, Target, Plus, Bell, ChevronLeft, ChevronRight } from "lucide-react";
import { useMemo } from "react";

export function Home() {
  const { settings, readings, setScreen, reminders } = useAppStore();
  const theme = themes[settings.theme];
  const lang = settings.language;
  const isRTL = lang === "ar";
  const ChevronNext = isRTL ? ChevronLeft : ChevronRight;

  // بيانات اليوم
  const today = useMemo(() => {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    return readings.filter((r) => r.timestamp >= start.getTime());
  }, [readings]);

  const latest = readings[0];

  const avg =
    today.length > 0
      ? Math.round(today.reduce((s, r) => s + r.value, 0) / today.length)
      : 0;
  const inRange = today.filter(
    (r) => getStatus(r.value, settings.targetMin, settings.targetMax) === "in_range",
  ).length;
  const inRangePct = today.length > 0 ? Math.round((inRange / today.length) * 100) : 0;

  const greeting = useMemo(() => {
    const h = new Date().getHours();
    if (h < 12) return t(lang, "good_morning");
    if (h < 17) return t(lang, "good_afternoon");
    if (h < 22) return t(lang, "good_evening");
    return t(lang, "good_night");
  }, [lang]);

  const activeReminders = reminders.filter((r) => r.enabled).length;

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className={`px-5 pt-8 pb-4 ${settings.theme === "modern" ? "bg-gradient-to-b from-fuchsia-500/10 to-transparent" : ""}`}>
        <div className="flex items-center justify-between">
          <div>
            <p className={`${theme.fontSizeSm} ${theme.textMuted}`}>{greeting}</p>
            <h1 className={`${theme.fontSize2xl} font-bold`}>
              {settings.userName}
            </h1>
          </div>
          <button
            onClick={() => setScreen("reminders")}
            className={`relative h-11 w-11 rounded-full ${theme.surface} ${theme.border} border flex items-center justify-center`}
            aria-label={t(lang, "nav_reminders")}
          >
            <Bell className="h-5 w-5" />
            {activeReminders > 0 && (
              <span className="absolute -top-1 -right-1 h-5 min-w-5 px-1 rounded-full bg-red-500 text-white text-xs flex items-center justify-center">
                {activeReminders}
              </span>
            )}
          </button>
        </div>
      </header>

      <div className="flex-1 overflow-y-auto px-5 pb-4 space-y-4">
        {/* البطاقة الرئيسية - آخر قراءة */}
        {latest ? (
          <ReadingHero reading={latest} />
        ) : (
          <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding} text-center`}>
            <Droplet className={`h-12 w-12 mx-auto mb-2 ${theme.textMuted}`} />
            <p className={`${theme.fontSizeLg} font-semibold`}>{t(lang, "no_readings_yet")}</p>
            <p className={`${theme.fontSizeSm} ${theme.textMuted} mt-1`}>
              {t(lang, "add_first_reading")}
            </p>
          </div>
        )}

        {/* الإحصائيات الثلاث */}
        <div className="grid grid-cols-3 gap-3">
          <StatCard
            icon={<TrendingUp className="h-4 w-4" />}
            label={t(lang, "avg_today")}
            value={avg > 0 ? String(avg) : "—"}
            unit="mg/dL"
            color="text-teal-600"
          />
          <StatCard
            icon={<Droplet className="h-4 w-4" />}
            label={t(lang, "readings_count")}
            value={String(today.length)}
            unit=""
            color="text-slate-700"
          />
          <StatCard
            icon={<Target className="h-4 w-4" />}
            label={t(lang, "in_range_pct")}
            value={today.length > 0 ? `${inRangePct}%` : "—"}
            unit=""
            color={inRangePct >= 70 ? "text-emerald-600" : "text-amber-600"}
          />
        </div>

        {/* أحدث القراءات */}
        <div>
          <div className="flex items-center justify-between mb-3 mt-2">
            <h2 className={`${theme.fontSizeLg} font-bold`}>{t(lang, "recent_readings")}</h2>
            <button
              onClick={() => setScreen("trends")}
              className={`flex items-center gap-1 ${theme.fontSizeSm} text-teal-600 dark:text-teal-400 font-semibold`}
            >
              {t(lang, "view_all")} <ChevronNext className="h-4 w-4" />
            </button>
          </div>

          <div className="space-y-2">
            {readings.slice(0, 5).map((r) => (
              <ReadingRow key={r.id} reading={r} />
            ))}
            {readings.length === 0 && (
              <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding} text-center ${theme.textMuted}`}>
                {t(lang, "no_readings_yet")}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

function ReadingHero({ reading }: { reading: Reading }) {
  const { settings, setScreen } = useAppStore();
  const theme = themes[settings.theme];
  const lang = settings.language;
  const status = getStatus(reading.value, settings.targetMin, settings.targetMax);
  const statusCls = statusClasses(settings.theme, status);

  const timeStr = new Date(reading.timestamp).toLocaleTimeString(lang === "ar" ? "ar-EG" : "en-US", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.97 }}
      animate={{ opacity: 1, scale: 1 }}
      className={`relative overflow-hidden ${theme.radius} ${theme.padding} ${
        settings.theme === "modern"
          ? "bg-gradient-to-br from-fuchsia-500/20 via-cyan-400/10 to-transparent border border-white/10"
          : settings.theme === "elder"
            ? "bg-slate-900 text-white border-2 border-slate-900"
            : "bg-gradient-to-br from-teal-600 to-emerald-600 text-white"
      }`}
    >
      {/* Decorative circle */}
      <div className="absolute -top-8 -right-8 h-32 w-32 rounded-full bg-white/10" />
      <div className="absolute -bottom-12 -left-4 h-24 w-24 rounded-full bg-white/5" />

      <div className="relative">
        <div className="flex items-center justify-between mb-2">
          <span className="text-sm font-medium opacity-90">
            {t(lang, "latest_reading")}
          </span>
          <span className={`px-2 py-0.5 rounded-full text-xs font-bold ${statusCls}`}>
            {statusLabel(lang, status)}
          </span>
        </div>

        <div className="flex items-end gap-2 mb-3">
          <span className="text-5xl font-bold leading-none">{reading.value}</span>
          <span className="text-lg opacity-80 mb-1">mg/dL</span>
        </div>

        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-xs px-2 py-1 rounded-md bg-white/20">
              {readingTypeLabel(lang, reading.type)}
            </span>
            <span className="text-sm opacity-80">{timeStr}</span>
          </div>
          <button
            onClick={() => setScreen("add")}
            className="h-9 w-9 rounded-full bg-white/20 flex items-center justify-center active:scale-90 transition-transform"
            aria-label={t(lang, "add_reading")}
          >
            <Plus className="h-5 w-5" />
          </button>
        </div>
      </div>
    </motion.div>
  );
}

function StatCard({
  icon,
  label,
  value,
  unit,
  color,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  unit: string;
  color: string;
}) {
  const { settings } = useAppStore();
  const theme = themes[settings.theme];
  return (
    <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding} flex flex-col items-center text-center`}>
      <div className={`${color} mb-1`}>{icon}</div>
      <div className={`${theme.fontSizeXl} font-bold ${color}`}>{value}</div>
      {unit && <div className={`${theme.fontSizeSm} ${theme.textMuted} -mt-1`}>{unit}</div>}
      <div className={`${theme.fontSizeSm} ${theme.textMuted} mt-1 leading-tight`}>{label}</div>
    </div>
  );
}

function ReadingRow({ reading }: { reading: Reading }) {
  const { settings } = useAppStore();
  const theme = themes[settings.theme];
  const lang = settings.language;
  const status = getStatus(reading.value, settings.targetMin, settings.targetMax);

  const date = new Date(reading.timestamp);
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();
  const isYesterday = new Date(now.getTime() - 86400000).toDateString() === date.toDateString();

  const dayLabel = isToday
    ? t(lang, "today")
    : isYesterday
      ? t(lang, "yesterday")
      : date.toLocaleDateString(lang === "ar" ? "ar-EG" : "en-US", { day: "numeric", month: "short" });

  const timeStr = date.toLocaleTimeString(lang === "ar" ? "ar-EG" : "en-US", {
    hour: "2-digit",
    minute: "2-digit",
  });

  return (
    <div className={`flex items-center gap-3 ${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
      <div className={`h-2.5 w-2.5 rounded-full ${statusDotColor(status)} flex-shrink-0`} />
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2">
          <span className={`font-bold ${theme.fontSizeBase}`}>{reading.value}</span>
          <span className={`${theme.fontSizeSm} ${theme.textMuted}`}>mg/dL</span>
        </div>
        <div className={`${theme.fontSizeSm} ${theme.textMuted}`}>
          {readingTypeLabel(lang, reading.type)} · {dayLabel} {timeStr}
        </div>
      </div>
      {reading.notes && (
        <span className={`${theme.fontSizeSm} ${theme.textMuted} truncate max-w-20`} title={reading.notes}>
          {reading.notes}
        </span>
      )}
    </div>
  );
}
