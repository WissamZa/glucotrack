"use client";

import { useState } from "react";
import { useAppStore } from "@/lib/store";
import { useAddReading, useUpdateReading } from "@/lib/api-hooks";
import { themes } from "@/lib/themes";
import { t, readingTypeLabel } from "@/lib/i18n";
import { getStatus } from "@/lib/types";
import type { ReadingType } from "@/lib/types";
import { motion } from "framer-motion";
import { X, Check, Minus, Plus, Droplet, Pencil } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

const READING_TYPES: ReadingType[] = [
  "fasting",
  "before_meal",
  "after_meal",
  "before_sleep",
  "after_exercise",
  "other",
];

function defaultTypeByHour(): ReadingType {
  const h = new Date().getHours();
  if (h >= 6 && h < 9) return "fasting";
  if (h >= 9 && h < 11) return "after_meal";
  if (h >= 11 && h < 14) return "before_meal";
  if (h >= 14 && h < 17) return "after_meal";
  if (h >= 21) return "before_sleep";
  return "other";
}

function toLocalDateTimeInput(ts: number): string {
  const d = new Date(ts);
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
  return d.toISOString().slice(0, 16);
}

export function AddReading() {
  const settings = useAppStore((s) => s.settings);
  const setScreen = useAppStore((s) => s.setScreen);
  const editingReadingId = useAppStore((s) => s.editingReadingId);
  const setEditingReadingId = useAppStore((s) => s.setEditingReadingId);
  const readings = useAppStore((s) => s.readings);
  const addReading = useAddReading();
  const updateReading = useUpdateReading();
  const { toast } = useToast();

  // ===== Edit mode: load existing reading values =====
  const editingReading = editingReadingId
    ? readings.find((r) => r.id === editingReadingId)
    : null;
  const isEditMode = !!editingReading;

  const theme = themes[settings?.theme ?? "classic"];
  const lang = settings?.language ?? "ar";
  const targetMin = settings?.targetMin ?? 80;
  const targetMax = settings?.targetMax ?? 180;

  // Initialize form state — when editing, use the reading's values.
  // We rely on a `key` prop at the parent level (page.tsx wraps AddReading with
  // editingReadingId as key) so the component fully remounts when switching
  // between add/edit, eliminating the need for a setState-in-effect reset.
  const [value, setValue] = useState<string>(
    editingReading ? String(editingReading.value) : "",
  );
  const [type, setType] = useState<ReadingType>(
    editingReading ? editingReading.type : defaultTypeByHour(),
  );
  const [notes, setNotes] = useState<string>(editingReading?.notes ?? "");
  const [carbs, setCarbs] = useState<string>(
    editingReading?.carbs != null ? String(editingReading.carbs) : "",
  );
  const [insulin, setInsulin] = useState<string>(
    editingReading?.insulin != null ? String(editingReading.insulin) : "",
  );
  const [timestamp, setTimestamp] = useState<string>(
    editingReading
      ? toLocalDateTimeInput(editingReading.timestamp)
      : (() => {
          const now = new Date();
          now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
          return now.toISOString().slice(0, 16);
        })(),
  );

  const numericValue = parseInt(value, 10);
  const isValid = !isNaN(numericValue) && numericValue >= 20 && numericValue <= 600;
  const status = isValid ? getStatus(numericValue, targetMin, targetMax) : null;

  const adjust = (delta: number) => {
    const cur = parseInt(value || "0", 10);
    const next = Math.max(0, Math.min(600, cur + delta));
    setValue(String(next));
  };

  const handleClose = () => {
    setEditingReadingId(null);
    setScreen("home");
  };

  const handleSave = () => {
    if (!isValid) {
      toast({
        title: t(lang, "invalid_value"),
        variant: "destructive",
      });
      return;
    }

    const payload = {
      value: numericValue,
      type,
      timestamp: new Date(timestamp).getTime(),
      notes: notes.trim() || undefined,
      carbs: carbs ? parseInt(carbs, 10) : undefined,
      insulin: insulin ? parseInt(insulin, 10) : undefined,
    };

    if (isEditMode && editingReading) {
      // ===== EDIT mode =====
      updateReading.mutate(
        { id: editingReading.id, ...payload },
        {
          onSuccess: () => {
            toast({ title: t(lang, "edited_success") });
            setEditingReadingId(null);
            setScreen("home");
          },
          onError: () => {
            toast({ title: t(lang, "invalid_value"), variant: "destructive" });
          },
        },
      );
    } else {
      // ===== ADD mode =====
      addReading.mutate(payload, {
        onSuccess: () => {
          toast({ title: t(lang, "saved_success") });
          setScreen("home");
        },
        onError: () => {
          toast({ title: t(lang, "invalid_value"), variant: "destructive" });
        },
      });
    }
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className="px-5 pt-8 pb-3 flex items-center justify-between">
        <h1 className={`${theme.fontSizeXl} font-bold flex items-center gap-2`}>
          {isEditMode ? (
            <>
              <Pencil className="h-5 w-5" />
              {t(lang, "edit_reading")}
            </>
          ) : (
            t(lang, "add_reading")
          )}
        </h1>
        <button
          onClick={handleClose}
          className="h-9 w-9 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center"
          aria-label={t(lang, "close")}
        >
          <X className="h-5 w-5" />
        </button>
      </header>

      <div className="flex-1 overflow-y-auto px-5 pb-4 space-y-4">
        {/* قيمة السكر - بطاقة كبيرة */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className={`${theme.surface} ${theme.border} border ${theme.radius} p-6 text-center`}
        >
          <label className={`${theme.fontSizeSm} ${theme.textMuted} block mb-3`}>
            {t(lang, "glucose_value")} (mg/dL)
          </label>

          <div className="flex items-center justify-center gap-4 mb-3">
            <button
              onClick={() => adjust(-10)}
              className="h-12 w-12 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center active:scale-90 transition-transform"
              aria-label="minus 10"
            >
              <Minus className="h-5 w-5" />
            </button>

            <div className="relative">
              <input
                type="number"
                inputMode="numeric"
                value={value}
                onChange={(e) => setValue(e.target.value)}
                placeholder="120"
                className={`w-32 text-center ${theme.fontSize2xl} font-bold bg-transparent border-b-2 ${
                  isValid
                    ? status === "in_range"
                      ? "border-emerald-500 text-emerald-600"
                      : "border-amber-500 text-amber-600"
                    : "border-slate-300"
                } focus:outline-none`}
                autoFocus
              />
              <Droplet className={`absolute -top-1 ${isRTL(lang) ? "-left-6" : "-right-6"} h-5 w-5 ${status === "in_range" ? "text-emerald-500" : "text-amber-500"}`} />
            </div>

            <button
              onClick={() => adjust(10)}
              className="h-12 w-12 rounded-full bg-slate-100 dark:bg-slate-700 flex items-center justify-center active:scale-90 transition-transform"
              aria-label="plus 10"
            >
              <Plus className="h-5 w-5" />
            </button>
          </div>

          {/* Quick presets */}
          <div className="flex justify-center gap-2 flex-wrap">
            {[80, 120, 160, 200].map((v) => (
              <button
                key={v}
                onClick={() => setValue(String(v))}
                className={`px-3 py-1.5 rounded-full text-xs font-semibold border ${
                  value === String(v)
                    ? "bg-teal-600 text-white border-teal-600"
                    : `${theme.surfaceAlt} ${theme.border} border ${theme.textMuted}`
                }`}
              >
                {v}
              </button>
            ))}
          </div>

          {/* Status preview */}
          {status && (
            <div className={`mt-3 text-sm font-semibold ${
              status === "in_range" ? "text-emerald-600" :
              status === "low" || status === "critical_low" ? "text-amber-600" :
              "text-orange-600"
            }`}>
              {t(lang, `status_${status}`)}
            </div>
          )}
        </motion.div>

        {/* نوع القياس */}
        <div>
          <label className={`${theme.fontSizeSm} font-semibold mb-2 block ${theme.text}`}>
            {t(lang, "measurement_type")}
          </label>
          <div className="grid grid-cols-3 gap-2">
            {READING_TYPES.map((rt) => (
              <button
                key={rt}
                onClick={() => setType(rt)}
                className={`px-2 py-2.5 rounded-xl border-2 text-xs font-semibold transition-all ${
                  type === rt
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                    : `${theme.border} ${theme.textMuted}`
                }`}
              >
                {readingTypeLabel(lang, rt)}
              </button>
            ))}
          </div>
        </div>

        {/* الوقت */}
        <div>
          <label className={`${theme.fontSizeSm} font-semibold mb-2 block ${theme.text}`}>
            {t(lang, "time")}
          </label>
          <input
            type="datetime-local"
            value={timestamp}
            onChange={(e) => setTimestamp(e.target.value)}
            className={`w-full px-4 py-3 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
          />
        </div>

        {/* تفاصيل إضافية */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className={`${theme.fontSizeSm} font-semibold mb-2 block ${theme.text}`}>
              {t(lang, "carbs_grams")}
            </label>
            <input
              type="number"
              inputMode="numeric"
              value={carbs}
              onChange={(e) => setCarbs(e.target.value)}
              placeholder="0"
              className={`w-full px-3 py-2.5 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
            />
          </div>
          <div>
            <label className={`${theme.fontSizeSm} font-semibold mb-2 block ${theme.text}`}>
              {t(lang, "insulin_units")}
            </label>
            <input
              type="number"
              inputMode="numeric"
              value={insulin}
              onChange={(e) => setInsulin(e.target.value)}
              placeholder="0"
              className={`w-full px-3 py-2.5 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
            />
          </div>
        </div>

        {/* ملاحظات */}
        <div>
          <label className={`${theme.fontSizeSm} font-semibold mb-2 block ${theme.text}`}>
            {t(lang, "notes")}
          </label>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder={t(lang, "notes_placeholder")}
            rows={2}
            className={`w-full px-4 py-3 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600 resize-none`}
          />
        </div>
      </div>

      {/* Save bar */}
      <div className="px-5 py-4 border-t border-slate-100 dark:border-slate-800">
        <div className="flex gap-3">
          <button
            onClick={handleClose}
            className={`px-5 py-3 rounded-2xl border-2 ${theme.border} font-semibold ${theme.text}`}
          >
            {t(lang, "cancel")}
          </button>
          <button
            onClick={handleSave}
            disabled={!isValid}
            className={`flex-1 py-3 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all ${
              isValid
                ? "bg-teal-600 text-white shadow-lg shadow-teal-600/30 active:scale-95"
                : "bg-slate-300 text-slate-500"
            }`}
          >
            <Check className="h-5 w-5" /> {t(lang, "save")}
          </button>
        </div>
      </div>
    </div>
  );
}

function isRTL(lang: string) {
  return lang === "ar";
}
