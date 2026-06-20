"use client";

import { useState, useMemo } from "react";
import { useAppStore, sortReadings } from "@/lib/store";
import { themes, chartLineColor, chartFillColor, chartTextColor, chartGridColor, statusDotColor, statusClasses } from "@/lib/themes";
import { t, readingTypeLabel, statusLabel } from "@/lib/i18n";
import { getStatus } from "@/lib/types";
import type { SortOrder } from "@/lib/types";
import {
  ResponsiveContainer,
  LineChart,
  Line,
  Area,
  AreaChart,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ReferenceArea,
  ReferenceLine,
  Cell,
} from "recharts";
import { motion } from "framer-motion";
import { Activity, ArrowDownUp, BarChart3, LineChart as LineIcon, Calendar } from "lucide-react";
import { ReadingActions } from "@/components/phone/ReadingActions";

type Period = "today" | "week" | "month";
type ChartKind = "line" | "area" | "bar";

export function Chart() {
  const settings = useAppStore((s) => s.settings);
  const readings = useAppStore((s) => s.readings);
  const sortOrder = useAppStore((s) => s.sortOrder);
  const setSortOrder = useAppStore((s) => s.setSortOrder);
  const setEditingReadingId = useAppStore((s) => s.setEditingReadingId);
  const setScreen = useAppStore((s) => s.setScreen);

  const [period, setPeriod] = useState<Period>("week");
  const [chartKind, setChartKind] = useState<ChartKind>("area");

  const theme = themes[settings?.theme ?? "classic"];
  const lang = settings?.language ?? "ar";
  const targetMin = settings?.targetMin ?? 80;
  const targetMax = settings?.targetMax ?? 180;

  // فلترة حسب الفترة
  const filtered = useMemo(() => {
    const now = Date.now();
    const dayMs = 24 * 60 * 60 * 1000;
    const cutoff =
      period === "today"
        ? new Date().setHours(0, 0, 0, 0)
        : period === "week"
          ? now - 7 * dayMs
          : now - 30 * dayMs;
    return readings
      .filter((r) => r.timestamp >= cutoff)
      .sort((a, b) => a.timestamp - b.timestamp);
  }, [readings, period]);

  // بيانات الرسم
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
      status: getStatus(r.value, targetMin, targetMax),
      ts: r.timestamp,
    }));
  }, [filtered, lang, period, targetMin, targetMax]);

  // متوسط متحرك لتنعيم المنحنى
  const smoothedData = useMemo(() => {
    if (chartData.length < 3) return chartData;
    const window = 3;
    return chartData.map((d, i) => {
      const start = Math.max(0, i - Math.floor(window / 2));
      const end = Math.min(chartData.length, i + Math.ceil(window / 2));
      const slice = chartData.slice(start, end);
      const avg = slice.reduce((s, x) => s + x.value, 0) / slice.length;
      return { ...d, avg: Math.round(avg) };
    });
  }, [chartData]);

  // إحصائيات
  const stats = useMemo(() => {
    if (filtered.length === 0) {
      return { avg: 0, max: 0, min: 0, inRange: 0, count: 0, range: 0 };
    }
    const values = filtered.map((r) => r.value);
    const inRange = filtered.filter(
      (r) => getStatus(r.value, targetMin, targetMax) === "in_range",
    ).length;
    return {
      avg: Math.round(values.reduce((s, v) => s + v, 0) / values.length),
      max: Math.max(...values),
      min: Math.min(...values),
      inRange: Math.round((inRange / filtered.length) * 100),
      count: filtered.length,
      range: Math.max(...values) - Math.min(...values),
    };
  }, [filtered, targetMin, targetMax]);

  // ترتيب القائمة (للقائمة أسفل الرسم)
  const sortedList = useMemo(
    () => sortReadings(filtered, sortOrder),
    [filtered, sortOrder],
  );

  const sortOptions: Array<{ v: SortOrder; label: string }> = [
    { v: "newest", label: t(lang, "sort_newest") },
    { v: "oldest", label: t(lang, "sort_oldest") },
    { v: "highest", label: t(lang, "sort_highest") },
    { v: "lowest", label: t(lang, "sort_lowest") },
  ];

  const barColor = (v: number) => {
    const s = getStatus(v, targetMin, targetMax);
    if (s === "in_range") return "#10b981";
    if (s === "low" || s === "critical_low") return "#f59e0b";
    return "#ef4444";
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className="px-5 pt-8 pb-2">
        <h1 className={`${theme.fontSize2xl} font-bold`}>{t(lang, "nav_chart")}</h1>
      </header>

      {/* Period selector */}
      <div className="px-5 pb-2">
        <div className={`flex gap-1 p-1 ${theme.surfaceAlt} ${theme.border} border rounded-full`}>
          {(["today", "week", "month"] as const).map((p) => (
            <button
              key={p}
              onClick={() => setPeriod(p)}
              className={`flex-1 py-2 rounded-full text-sm font-semibold transition-all ${
                period === p ? "bg-teal-600 text-white shadow" : theme.textMuted
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
            {/* Chart type selector */}
            <div className={`flex gap-2 ${theme.surfaceAlt} ${theme.border} border rounded-xl p-1`}>
              {([
                { v: "area", icon: <Activity className="h-4 w-4" />, label: lang === "ar" ? "منحنى" : "Area" },
                { v: "line", icon: <LineIcon className="h-4 w-4" />, label: lang === "ar" ? "خطي" : "Line" },
                { v: "bar", icon: <BarChart3 className="h-4 w-4" />, label: lang === "ar" ? "أعمدة" : "Bar" },
              ] as const).map((c) => (
                <button
                  key={c.v}
                  onClick={() => setChartKind(c.v as ChartKind)}
                  className={`flex-1 py-2 rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                    chartKind === c.v
                      ? "bg-teal-600 text-white"
                      : theme.textMuted
                  }`}
                >
                  {c.icon}
                  {c.label}
                </button>
              ))}
            </div>

            {/* Chart */}
            <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-4`}>
              <div className="flex items-center justify-between mb-3">
                <h2 className={`${theme.fontSizeBase} font-bold`}>{t(lang, "glucose_chart")}</h2>
                <span className={`text-xs ${theme.textMuted} flex items-center gap-1`}>
                  <Calendar className="h-3 w-3" />
                  {filtered.length} {t(lang, "stat_readings")}
                </span>
              </div>

              <div className="h-64" dir="ltr">
                <ResponsiveContainer width="100%" height="100%">
                  {chartKind === "bar" ? (
                    <BarChart data={chartData} margin={{ top: 5, right: 8, left: -16, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke={chartGridColor(theme === themes.classic ? "classic" : (settings?.theme ?? "classic"))} />
                      <XAxis
                        dataKey="time"
                        tick={{ fontSize: 10, fill: chartTextColor(settings?.theme ?? "classic") }}
                        tickLine={false}
                        axisLine={false}
                        interval="preserveStartEnd"
                      />
                      <YAxis
                        domain={[40, 300]}
                        tick={{ fontSize: 10, fill: chartTextColor(settings?.theme ?? "classic") }}
                        tickLine={false}
                        axisLine={false}
                      />
                      <Tooltip
                        contentStyle={{
                          background: settings?.theme === "modern" ? "rgba(15,23,42,0.95)" : "#fff",
                          border: `1px solid ${chartGridColor(settings?.theme ?? "classic")}`,
                          borderRadius: 12,
                          fontSize: 12,
                          color: settings?.theme === "modern" ? "#fff" : "#0f172a",
                        }}
                        formatter={(value: number) => [`${value} mg/dL`, t(lang, "glucose_value")]}
                      />
                      <ReferenceArea y1={targetMin} y2={targetMax} fill="#10b981" fillOpacity={0.08} />
                      <Bar dataKey="value" radius={[4, 4, 0, 0]}>
                        {chartData.map((entry, i) => (
                          <Cell key={i} fill={barColor(entry.value)} />
                        ))}
                      </Bar>
                    </BarChart>
                  ) : chartKind === "line" ? (
                    <LineChart data={chartData} margin={{ top: 5, right: 8, left: -16, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke={chartGridColor(settings?.theme ?? "classic")} />
                      <XAxis
                        dataKey="time"
                        tick={{ fontSize: 10, fill: chartTextColor(settings?.theme ?? "classic") }}
                        tickLine={false}
                        axisLine={false}
                        interval="preserveStartEnd"
                      />
                      <YAxis
                        domain={[40, 300]}
                        tick={{ fontSize: 10, fill: chartTextColor(settings?.theme ?? "classic") }}
                        tickLine={false}
                        axisLine={false}
                      />
                      <Tooltip
                        contentStyle={{
                          background: settings?.theme === "modern" ? "rgba(15,23,42,0.95)" : "#fff",
                          border: `1px solid ${chartGridColor(settings?.theme ?? "classic")}`,
                          borderRadius: 12,
                          fontSize: 12,
                          color: settings?.theme === "modern" ? "#fff" : "#0f172a",
                        }}
                        formatter={(value: number) => [`${value} mg/dL`, t(lang, "glucose_value")]}
                      />
                      <ReferenceArea y1={targetMin} y2={targetMax} fill="#10b981" fillOpacity={0.1} />
                      <ReferenceLine y={targetMin} stroke="#10b981" strokeDasharray="4 4" strokeOpacity={0.5} />
                      <ReferenceLine y={targetMax} stroke="#10b981" strokeDasharray="4 4" strokeOpacity={0.5} />
                      <Line
                        type="monotone"
                        dataKey="value"
                        stroke={chartLineColor(settings?.theme ?? "classic")}
                        strokeWidth={2.5}
                        dot={{ r: 3, fill: chartLineColor(settings?.theme ?? "classic") }}
                        activeDot={{ r: 5 }}
                      />
                    </LineChart>
                  ) : (
                    <AreaChart data={smoothedData} margin={{ top: 5, right: 8, left: -16, bottom: 0 }}>
                      <defs>
                        <linearGradient id="glucoseGradient" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="0%" stopColor={chartLineColor(settings?.theme ?? "classic")} stopOpacity={0.5} />
                          <stop offset="100%" stopColor={chartLineColor(settings?.theme ?? "classic")} stopOpacity={0.05} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke={chartGridColor(settings?.theme ?? "classic")} />
                      <XAxis
                        dataKey="time"
                        tick={{ fontSize: 10, fill: chartTextColor(settings?.theme ?? "classic") }}
                        tickLine={false}
                        axisLine={false}
                        interval="preserveStartEnd"
                      />
                      <YAxis
                        domain={[40, 300]}
                        tick={{ fontSize: 10, fill: chartTextColor(settings?.theme ?? "classic") }}
                        tickLine={false}
                        axisLine={false}
                      />
                      <Tooltip
                        contentStyle={{
                          background: settings?.theme === "modern" ? "rgba(15,23,42,0.95)" : "#fff",
                          border: `1px solid ${chartGridColor(settings?.theme ?? "classic")}`,
                          borderRadius: 12,
                          fontSize: 12,
                          color: settings?.theme === "modern" ? "#fff" : "#0f172a",
                        }}
                        formatter={(value: number) => [`${value} mg/dL`, t(lang, "glucose_value")]}
                      />
                      <ReferenceArea y1={targetMin} y2={targetMax} fill="#10b981" fillOpacity={0.12} />
                      <ReferenceLine y={targetMin} stroke="#10b981" strokeDasharray="4 4" strokeOpacity={0.5} />
                      <ReferenceLine y={targetMax} stroke="#10b981" strokeDasharray="4 4" strokeOpacity={0.5} />
                      <Area
                        type="monotone"
                        dataKey="value"
                        stroke={chartLineColor(settings?.theme ?? "classic")}
                        strokeWidth={2.5}
                        fill="url(#glucoseGradient)"
                        dot={{ r: 2, fill: chartLineColor(settings?.theme ?? "classic") }}
                        activeDot={{ r: 5 }}
                      />
                    </AreaChart>
                  )}
                </ResponsiveContainer>
              </div>

              {/* Legend */}
              <div className={`flex flex-wrap items-center gap-3 mt-3 ${theme.fontSizeSm}`}>
                <div className="flex items-center gap-1.5">
                  <div className="h-2 w-3 bg-emerald-500/30 rounded" />
                  <span className={theme.textMuted}>{targetMin}-{targetMax} mg/dL</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <div className="h-2 w-2 rounded-full bg-emerald-500" />
                  <span className={theme.textMuted}>{t(lang, "status_in_range")}</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <div className="h-2 w-2 rounded-full bg-amber-500" />
                  <span className={theme.textMuted}>{t(lang, "status_low")}</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <div className="h-2 w-2 rounded-full bg-red-500" />
                  <span className={theme.textMuted}>{t(lang, "status_high")}</span>
                </div>
              </div>
            </div>

            {/* Stats */}
            <div className={`grid grid-cols-3 gap-2 ${theme.surface} ${theme.border} border ${theme.radius} p-3`}>
              <StatCell label={t(lang, "stat_avg")} value={stats.avg} unit="mg/dL" color="text-teal-600" />
              <StatCell label={t(lang, "stat_min")} value={stats.min} unit="mg/dL" color="text-emerald-600" />
              <StatCell label={t(lang, "stat_max")} value={stats.max} unit="mg/dL" color="text-orange-600" />
              <StatCell label={t(lang, "stat_in_range")} value={`${stats.inRange}%`} unit="" color="text-emerald-600" />
              <StatCell label={lang === "ar" ? "المدى" : "Range"} value={stats.range} unit="mg/dL" color="text-slate-700" />
              <StatCell label={t(lang, "stat_readings")} value={stats.count} unit="" color="text-slate-700" />
            </div>

            {/* Sort selector */}
            <div className={`flex items-center gap-2 ${theme.fontSizeSm}`}>
              <ArrowDownUp className="h-4 w-4 text-teal-600" />
              <span className={theme.textMuted}>{t(lang, "sort_by")}:</span>
              <div className="flex gap-1 flex-wrap">
                {sortOptions.map((opt) => (
                  <button
                    key={opt.v}
                    onClick={() => setSortOrder(opt.v)}
                    className={`px-2.5 py-1 rounded-full text-xs font-semibold border ${
                      sortOrder === opt.v
                        ? "bg-teal-600 text-white border-teal-600"
                        : `${theme.surfaceAlt} ${theme.border} border ${theme.textMuted}`
                    }`}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>

            {/* Readings list */}
            <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-2`}>
              <h2 className={`${theme.fontSizeBase} font-bold mb-2 px-2 pt-2`}>
                {t(lang, "recent_readings")} ({sortedList.length})
              </h2>
              <div className="max-h-72 overflow-y-auto space-y-1 px-1">
                {sortedList.map((r) => {
                  const status = getStatus(r.value, targetMin, targetMax);
                  const statusCls = statusClasses(settings?.theme ?? "classic", status);
                  return (
                    <motion.div
                      key={r.id}
                      layout
                      className={`flex items-center gap-2 px-2 py-2 rounded-lg ${theme.surfaceAlt}`}
                    >
                      <div className={`h-2 w-2 rounded-full ${statusDotColor(status)} flex-shrink-0`} />
                      <span className={`font-bold ${theme.fontSizeSm}`}>{r.value}</span>
                      <span className={`${theme.fontSizeSm} ${theme.textMuted}`}>mg/dL</span>
                      <span className={`px-1.5 py-0.5 rounded-md text-[10px] font-bold ${statusCls}`}>
                        {statusLabel(lang, status)}
                      </span>
                      <div className="flex-1 min-w-0">
                        <span className={`${theme.fontSizeSm} ${theme.textMuted} block truncate`}>
                          {readingTypeLabel(lang, r.type)}
                          {r.notes ? ` · ${r.notes}` : ""}
                        </span>
                      </div>
                      <span className={`${theme.fontSizeSm} ${theme.textMuted} flex-shrink-0`}>
                        {new Date(r.timestamp).toLocaleString(lang === "ar" ? "ar-EG" : "en-US", {
                          day: "numeric",
                          month: "short",
                          hour: "2-digit",
                          minute: "2-digit",
                        })}
                      </span>
                      <ReadingActions
                        reading={r}
                        onEdit={() => {
                          setEditingReadingId(r.id);
                          setScreen("add");
                        }}
                      />
                    </motion.div>
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

function StatCell({
  label,
  value,
  unit,
  color,
}: {
  label: string;
  value: number | string;
  unit: string;
  color: string;
}) {
  const settings = useAppStore((s) => s.settings)!;
  const theme = themes[settings.theme];
  return (
    <div className="flex flex-col items-center text-center">
      <div className={`${theme.fontSizeLg} font-bold ${color} leading-none`}>{value}</div>
      {unit && <div className={`text-[10px] ${theme.textMuted} -mt-0.5`}>{unit}</div>}
      <div className={`text-[10px] ${theme.textMuted} mt-0.5 leading-tight`}>{label}</div>
    </div>
  );
}
