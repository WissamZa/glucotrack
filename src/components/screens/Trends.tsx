"use client";

import { useState, useMemo } from "react";
import { useAppStore } from "@/lib/store";
import { themes, chartLineColor, chartFillColor, chartTextColor, chartGridColor, statusDotColor } from "@/lib/themes";
import { t, readingTypeLabel } from "@/lib/i18n";
import { getStatus } from "@/lib/types";
import type { ReadingType } from "@/lib/types";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ReferenceArea,
} from "recharts";
import { Droplet, TrendingUp, Activity, Target } from "lucide-react";
import { motion } from "framer-motion";

type Period = "today" | "week" | "month";

export function Trends() {
  const { settings, readings } = useAppStore();
  const theme = themes[settings.theme];
  const lang = settings.language;
  const [period, setPeriod] = useState<Period>("week");

  // فلترة البيانات حسب الفترة
  const filtered = useMemo(() => {
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    const cutoff =
      period === "today"
        ? new Date().setHours(0, 0, 0, 0)
        : period === "week"
          ? now - 7 * dayMs
          : now - 30 * dayMs;
    return readings.filter((r) => r.timestamp >= cutoff).sort((a, b) => a.timestamp - b.timestamp);
  }, [readings, period]);

  // إعداد بيانات الرسم
  const chartData = useMemo(() => {
    return filtered.map((r) => ({
      time: new Date(r.timestamp).toLocaleString(lang === "ar" ? "ar-EG" : "en-US", {
        month: period === "month" ? "short" : undefined,
        day: period !== "today" ? "numeric" : undefined,
        hour: period === "today" ? "2-digit" : undefined,
        minute: period === "today" ? "2-digit" : undefined,
      }),
      value: r.value,
      type: r.type,
      status: getStatus(r.value, settings.targetMin, settings.targetMax),
    }));
  }, [filtered, lang, period, settings.targetMin, settings.targetMax]);

  // إحصائيات
  const stats = useMemo(() => {
    if (filtered.length === 0) {
      return { avg: 0, max: 0, min: 0, inRange: 0, count: 0 };
    }
    const values = filtered.map((r) => r.value);
    const inRange = filtered.filter(
      (r) => getStatus(r.value, settings.targetMin, settings.targetMax) === "in_range",
    ).length;
    return {
      avg: Math.round(values.reduce((s, v) => s + v, 0) / values.length),
      max: Math.max(...values),
      min: Math.min(...values),
      inRange: Math.round((inRange / filtered.length) * 100),
      count: filtered.length,
    };
  }, [filtered, settings.targetMin, settings.targetMax]);

  // توزيع حسب النوع
  const byType = useMemo(() => {
    const counts: Partial<Record<ReadingType, number>> = {};
    for (const r of filtered) {
      counts[r.type] = (counts[r.type] || 0) + 1;
    }
    return Object.entries(counts).sort((a, b) => (b[1] || 0) - (a[1] || 0));
  }, [filtered]);

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className="px-5 pt-8 pb-3">
        <h1 className={`${theme.fontSize2xl} font-bold`}>{t(lang, "trends")}</h1>
      </header>

      {/* Period selector */}
      <div className="px-5 pb-3">
        <div className={`flex gap-1 p-1 ${theme.surfaceAlt} ${theme.border} border rounded-full`}>
          {(["today", "week", "month"] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`flex-1 py-2 rounded-full text-sm font-semibold transition-all ${
                period === p
                  ? "bg-teal-600 text-white shadow"
                  : theme.textMuted
              }`}
            >
              {t(lang, `period_${p}`)}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-5 pb-4 space-y-4">
        {filtered.length === 0 ? (
          <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-8 text-center`}>
            <Activity className={`h-12 w-12 mx-auto mb-2 ${theme.textMuted}`} />
            <p className={`${theme.fontSizeBase} ${theme.textMuted}`}>
              {t(lang, "no_data_period")}
            </p>
          </div>
        ) : (
          <>
            {/* الإحصائيات */}
            <div className="grid grid-cols-4 gap-2">
              <StatBox icon={<TrendingUp className="h-4 w-4" />} value={stats.avg} label={t(lang, "stat_avg")} color="text-teal-600" />
              <StatBox icon={<Activity className="h-4 w-4" />} value={stats.max} label={t(lang, "stat_max")} color="text-orange-600" />
              <StatBox icon={<Droplet className="h-4 w-4" />} value={stats.min} label={t(lang, "stat_min")} color="text-amber-600" />
              <StatBox icon={<Target className="h-4 w-4" />} value={`${stats.inRange}%`} label={t(lang, "stat_in_range")} color="text-emerald-600" />
            </div>

            {/* الرسم البياني */}
            <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-4`}>
              <h2 className={`${theme.fontSizeBase} font-bold mb-3`}>
                {t(lang, "glucose_chart")}
              </h2>
              <div className="h-56" dir="ltr">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 5, right: 8, left: -16, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke={chartGridColor(settings.theme)} />
                    <XAxis
                      dataKey="time"
                      tick={{ fontSize: 10, fill: chartTextColor(settings.theme) }}
                      tickLine={false}
                      axisLine={false}
                      interval="preserveStartEnd"
                    />
                    <YAxis
                      domain={[40, 300]}
                      tick={{ fontSize: 10, fill: chartTextColor(settings.theme) }}
                      tickLine={false}
                      axisLine={false}
                    />
                    <Tooltip
                      contentStyle={{
                        background: settings.theme === "modern" ? "rgba(15,23,42,0.95)" : "#fff",
                        border: `1px solid ${chartGridColor(settings.theme)}`,
                        borderRadius: 12,
                        fontSize: 12,
                        color: settings.theme === "modern" ? "#fff" : "#0f172a",
                      }}
                      labelStyle={{ color: chartTextColor(settings.theme) }}
                      formatter={(value: number) => [`${value} mg/dL`, t(lang, "glucose_value")]}
                    />
                    <ReferenceArea
                      y1={settings.targetMin}
                      y2={settings.targetMax}
                      fill="#10b981"
                      fillOpacity={0.1}
                    />
                    <Line
                      type="monotone"
                      dataKey="value"
                      stroke={chartLineColor(settings.theme)}
                      strokeWidth={2.5}
                      dot={{ r: 3, fill: chartLineColor(settings.theme) }}
                      activeDot={{ r: 5 }}
                      fill={chartFillColor(settings.theme)}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
              <div className={`flex items-center gap-2 mt-2 ${theme.fontSizeSm} ${theme.textMuted}`}>
                <div className="h-2 w-3 bg-emerald-500/30 rounded" />
                <span>
                  {t(lang, "stat_in_range")}: {settings.targetMin}-{settings.targetMax} mg/dL
                </span>
              </div>
            </div>

            {/* توزيع حسب النوع */}
            <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-4`}>
              <h2 className={`${theme.fontSizeBase} font-bold mb-3`}>
                {t(lang, "by_type")}
              </h2>
              <div className="space-y-2">
                {byType.map(([type, count]) => {
                  const typedType = type as ReadingType;
                  const pct = Math.round(((count || 0) / filtered.length) * 100);
                  return (
                    <div key={type} className="flex items-center gap-3">
                      <div className={`w-20 ${theme.fontSizeSm} ${theme.text} truncate`}>
                        {readingTypeLabel(lang, typedType)}
                      </div>
                      <div className={`flex-1 h-6 rounded-full ${theme.surfaceAlt} overflow-hidden`}>
                        <motion.div
                          initial={{ width: 0 }}
                          animate={{ width: `${pct}%` }}
                          transition={{ duration: 0.5 }}
                          className="h-full bg-gradient-to-r from-teal-500 to-emerald-500 rounded-full flex items-center justify-end pr-2"
                        >
                          <span className="text-xs text-white font-bold">{count}</span>
                        </motion.div>
                      </div>
                      <div className={`w-10 text-end ${theme.fontSizeSm} ${theme.textMuted}`}>{pct}%</div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* قائمة القراءات */}
            <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-2`}>
              <h2 className={`${theme.fontSizeBase} font-bold mb-2 px-2 pt-2`}>
                {t(lang, "recent_readings")} ({filtered.length})
              </h2>
              <div className="max-h-64 overflow-y-auto space-y-1 px-1">
                {filtered
                  .slice()
                  .reverse()
                  .map((r) => {
                    const status = getStatus(r.value, settings.targetMin, settings.targetMax);
                    return (
                      <div
                        key={r.id}
                        className={`flex items-center gap-2 px-2 py-2 rounded-lg ${theme.surfaceAlt}`}
                      >
                        <div className={`h-2 w-2 rounded-full ${statusDotColor(status)} flex-shrink-0`} />
                        <span className={`font-bold ${theme.fontSizeSm}`}>{r.value}</span>
                        <span className={`${theme.fontSizeSm} ${theme.textMuted}`}>mg/dL</span>
                        <span className={`flex-1 ${theme.fontSizeSm} ${theme.textMuted} truncate`}>
                          {readingTypeLabel(lang, r.type)}
                          {r.notes ? ` · ${r.notes}` : ""}
                        </span>
                        <span className={`${theme.fontSizeSm} ${theme.textMuted}`}>
                          {new Date(r.timestamp).toLocaleString(lang === "ar" ? "ar-EG" : "en-US", {
                            day: "numeric",
                            month: "short",
                            hour: "2-digit",
                            minute: "2-digit",
                          })}
                        </span>
                      </div>
                    );
                  })}
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function StatBox({
  icon,
  value,
  label,
  color,
}: {
  icon: React.ReactNode;
  value: number | string;
  label: string;
  color: string;
}) {
  const { settings } = useAppStore();
  const theme = themes[settings.theme];
  return (
    <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-2.5 flex flex-col items-center text-center`}>
      <div className={`${color} mb-0.5`}>{icon}</div>
      <div className={`${theme.fontSizeBase} font-bold ${color} leading-none`}>{value}</div>
      <div className={`${theme.fontSizeSm} ${theme.textMuted} leading-tight mt-0.5`}>{label}</div>
    </div>
  );
}


