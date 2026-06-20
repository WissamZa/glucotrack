"use client";

import { useState } from "react";
import { useAppStore } from "@/lib/store";
import { themes } from "@/lib/themes";
import { t, readingTypeLabel } from "@/lib/i18n";
import type { ReadingType } from "@/lib/types";
import { motion, AnimatePresence } from "framer-motion";
import { Bell, Plus, Trash2, Clock, BellOff } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Switch } from "@/components/ui/switch";

const READING_TYPES: ReadingType[] = [
  "fasting",
  "before_meal",
  "after_meal",
  "before_sleep",
  "after_exercise",
  "other",
];

export function Reminders() {
  const { settings, reminders, toggleReminder, deleteReminder, addReminder } = useAppStore();
  const theme = themes[settings.theme];
  const lang = settings.language;
  const { toast } = useToast();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [newTime, setNewTime] = useState("08:00");
  const [newType, setNewType] = useState<ReadingType>("fasting");
  const [newLabel, setNewLabel] = useState("");

  const handleAdd = () => {
    addReminder({
      time: newTime,
      type: newType,
      label: newLabel.trim() || readingTypeLabel(lang, newType),
      enabled: true,
    });
    toast({ title: t(lang, "reminder_added") });
    setDialogOpen(false);
    setNewLabel("");
  };

  const handleDelete = (id: string) => {
    deleteReminder(id);
    toast({ title: t(lang, "reminder_deleted") });
  };

  const sortedReminders = [...reminders].sort((a, b) => a.time.localeCompare(b.time));

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className="px-5 pt-8 pb-3 flex items-center justify-between">
        <div>
          <h1 className={`${theme.fontSize2xl} font-bold`}>{t(lang, "reminders")}</h1>
          <p className={`${theme.fontSizeSm} ${theme.textMuted}`}>
            {reminders.filter((r) => r.enabled).length} / {reminders.length} {lang === "ar" ? "نشط" : "active"}
          </p>
        </div>
        <button
          onClick={() => setDialogOpen(true)}
          className="h-11 w-11 rounded-full bg-teal-600 text-white flex items-center justify-center shadow-lg shadow-teal-600/30 active:scale-90 transition-transform"
          aria-label={t(lang, "add_reminder")}
        >
          <Plus className="h-5 w-5" />
        </button>
      </header>

      <div className="flex-1 overflow-y-auto px-5 pb-4">
        {sortedReminders.length === 0 ? (
          <div className={`${theme.surface} ${theme.border} border ${theme.radius} p-8 text-center mt-4`}>
            <BellOff className={`h-12 w-12 mx-auto mb-3 ${theme.textMuted}`} />
            <p className={`${theme.fontSizeBase} font-semibold`}>{t(lang, "no_reminders")}</p>
            <p className={`${theme.fontSizeSm} ${theme.textMuted} mt-1`}>
              {t(lang, "add_reminder")}
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            <AnimatePresence>
              {sortedReminders.map((r) => (
                <motion.div
                  key={r.id}
                  layout
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, x: -50 }}
                  className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding} flex items-center gap-3`}
                >
                  <div className={`h-12 w-12 rounded-xl flex flex-col items-center justify-center flex-shrink-0 ${
                    r.enabled
                      ? "bg-teal-100 dark:bg-teal-900/40 text-teal-700 dark:text-teal-300"
                      : "bg-slate-100 dark:bg-slate-800 text-slate-400"
                  }`}>
                    <Clock className="h-5 w-5" />
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className={`flex items-center gap-2`}>
                      <span className={`${theme.fontSizeLg} font-bold`}>{r.time}</span>
                      <span className={`px-2 py-0.5 rounded-md text-xs ${theme.surfaceAlt} ${theme.textMuted}`}>
                        {readingTypeLabel(lang, r.type)}
                      </span>
                    </div>
                    <div className={`${theme.fontSizeSm} ${theme.textMuted} truncate`}>
                      {r.label}
                    </div>
                  </div>

                  <Switch
                    checked={r.enabled}
                    onCheckedChange={() => toggleReminder(r.id)}
                    aria-label={t(lang, "enable_reminder")}
                  />
                  <button
                    onClick={() => handleDelete(r.id)}
                    className="h-9 w-9 rounded-lg text-red-500 hover:bg-red-50 dark:hover:bg-red-900/30 flex items-center justify-center flex-shrink-0"
                    aria-label={t(lang, "delete_reminder")}
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        )}
      </div>

      {/* Dialog */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>{t(lang, "add_reminder")}</DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div>
              <label className={`text-sm font-semibold mb-2 block ${theme.text}`}>
                {t(lang, "reminder_time")}
              </label>
              <input
                type="time"
                value={newTime}
                onChange={(e) => setNewTime(e.target.value)}
                className="w-full px-4 py-3 rounded-xl border-2 border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 focus:outline-none focus:border-teal-600"
              />
            </div>

            <div>
              <label className={`text-sm font-semibold mb-2 block ${theme.text}`}>
                {t(lang, "measurement_type")}
              </label>
              <div className="grid grid-cols-3 gap-2">
                {READING_TYPES.map((rt) => (
                  <button
                    key={rt}
                    onClick={() => setNewType(rt)}
                    className={`px-2 py-2 rounded-xl border-2 text-xs font-semibold transition-all ${
                      newType === rt
                        ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                        : "border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400"
                    }`}
                  >
                    {readingTypeLabel(lang, rt)}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className={`text-sm font-semibold mb-2 block ${theme.text}`}>
                {t(lang, "reminder_label")}
              </label>
              <input
                value={newLabel}
                onChange={(e) => setNewLabel(e.target.value)}
                placeholder={readingTypeLabel(lang, newType)}
                className="w-full px-4 py-3 rounded-xl border-2 border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 focus:outline-none focus:border-teal-600"
              />
            </div>
          </div>

          <DialogFooter>
            <button
              onClick={() => setDialogOpen(false)}
              className="px-5 py-2.5 rounded-xl border-2 border-slate-200 dark:border-slate-700 font-semibold"
            >
              {t(lang, "cancel")}
            </button>
            <button
              onClick={handleAdd}
              className="px-5 py-2.5 rounded-xl bg-teal-600 text-white font-bold"
            >
              {t(lang, "save")}
            </button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
