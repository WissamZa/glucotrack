"use client";

import { useState } from "react";
import { useAppStore } from "@/lib/store";
import { themes } from "@/lib/themes";
import { t, diabetesTypeLabel } from "@/lib/i18n";
import type { Language, ThemeStyle, DiabetesType, GlucoseUnit } from "@/lib/types";
import { motion } from "framer-motion";
import {
  Globe,
  Palette,
  HeartPulse,
  Target,
  User,
  Bluetooth,
  Info,
  RotateCcw,
  ChevronLeft,
  ChevronRight,
  Stethoscope,
  Moon,
  Sun,
  Check,
  AlertCircle,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog";

export function Settings() {
  const { settings, updateSettings, resetAll } = useAppStore();
  const theme = themes[settings.theme];
  const lang = settings.language;
  const isRTL = lang === "ar";
  const { toast } = useToast();
  const [nameDraft, setNameDraft] = useState(settings.userName);

  const ChevronNext = isRTL ? ChevronLeft : ChevronRight;

  const handleReset = () => {
    resetAll();
    toast({ title: t(lang, "reset_done") });
  };

  const saveName = () => {
    updateSettings({ userName: nameDraft.trim() || settings.userName });
    toast({ title: t(lang, "save_settings") });
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <header className="px-5 pt-8 pb-3">
        <h1 className={`${theme.fontSize2xl} font-bold`}>{t(lang, "settings")}</h1>
      </header>

      <div className="flex-1 overflow-y-auto px-5 pb-4 space-y-4">
        {/* ===== قسم المظهر ===== */}
        <SectionTitle icon={<Palette className="h-4 w-4" />} title={t(lang, "appearance")} />

        {/* اختيار اللغة */}
        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-3">
            <Globe className="h-5 w-5 text-teal-600" />
            <span className={`${theme.fontSizeBase} font-semibold flex-1`}>
              {t(lang, "language")}
            </span>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {([
              { v: "ar", label: "العربية", flag: "🇸🇦" },
              { v: "en", label: "English", flag: "🇬🇧" },
            ] as const).map((l) => (
              <button
                key={l.v}
                onClick={() => updateSettings({ language: l.v as Language })}
                className={`py-2.5 rounded-xl border-2 flex items-center justify-center gap-2 font-semibold text-sm transition-all ${
                  settings.language === l.v
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                    : `${theme.border} ${theme.textMuted}`
                }`}
              >
                <span className="text-lg">{l.flag}</span>
                {l.label}
              </button>
            ))}
          </div>
        </div>

        {/* اختيار النمط */}
        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-3">
            <Palette className="h-5 w-5 text-teal-600" />
            <span className={`${theme.fontSizeBase} font-semibold flex-1`}>
              {t(lang, "display_style")}
            </span>
          </div>
          <div className="space-y-2">
            {([
              { v: "classic", icon: <Stethoscope className="h-4 w-4" />, label: t(lang, "style_classic") },
              { v: "modern", icon: <Moon className="h-4 w-4" />, label: t(lang, "style_modern") },
              { v: "elder", icon: <Sun className="h-4 w-4" />, label: t(lang, "style_elder") },
            ] as const).map((s) => (
              <button
                key={s.v}
                onClick={() => updateSettings({ theme: s.v as ThemeStyle })}
                className={`w-full py-2.5 px-3 rounded-xl border-2 flex items-center gap-3 transition-all ${
                  settings.theme === s.v
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30"
                    : theme.border
                }`}
              >
                <span className={settings.theme === s.v ? "text-teal-600" : theme.textMuted}>
                  {s.icon}
                </span>
                <span className={`${theme.fontSizeBase} font-medium flex-1 text-start`}>
                  {s.label}
                </span>
                {settings.theme === s.v && (
                  <Check className="h-4 w-4 text-teal-600" />
                )}
              </button>
            ))}
          </div>
        </div>

        {/* ===== قسم الصحة ===== */}
        <SectionTitle icon={<HeartPulse className="h-4 w-4" />} title={t(lang, "health")} />

        {/* نوع السكري */}
        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-3">
            <HeartPulse className="h-5 w-5 text-teal-600" />
            <span className={`${theme.fontSizeBase} font-semibold flex-1`}>
              {t(lang, "diabetes_type")}
            </span>
          </div>
          <div className="grid grid-cols-3 gap-2">
            {([
              { v: "type1", label: t(lang, "diabetes_type1") },
              { v: "type2", label: t(lang, "diabetes_type2") },
              { v: "gestational", label: t(lang, "diabetes_gestational") },
            ] as const).map((d) => (
              <button
                key={d.v}
                onClick={() => updateSettings({ diabetesType: d.v as DiabetesType })}
                className={`py-2 rounded-xl border-2 text-xs font-semibold transition-all ${
                  settings.diabetesType === d.v
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                    : `${theme.border} ${theme.textMuted}`
                }`}
              >
                {d.label}
              </button>
            ))}
          </div>
        </div>

        {/* النطاق المستهدف */}
        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-3">
            <Target className="h-5 w-5 text-teal-600" />
            <span className={`${theme.fontSizeBase} font-semibold flex-1`}>
              {t(lang, "glucose_targets")} (mg/dL)
            </span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={`${theme.fontSizeSm} ${theme.textMuted} block mb-1`}>
                {t(lang, "target_min")}
              </label>
              <input
                type="number"
                value={settings.targetMin}
                onChange={(e) =>
                  updateSettings({ targetMin: Math.max(40, Math.min(150, parseInt(e.target.value) || 80)) })
                }
                className={`w-full px-3 py-2 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
              />
            </div>
            <div>
              <label className={`${theme.fontSizeSm} ${theme.textMuted} block mb-1`}>
                {t(lang, "target_max")}
              </label>
              <input
                type="number"
                value={settings.targetMax}
                onChange={(e) =>
                  updateSettings({ targetMax: Math.max(120, Math.min(300, parseInt(e.target.value) || 180)) })
                }
                className={`w-full px-3 py-2 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
              />
            </div>
          </div>
        </div>

        {/* وحدة القياس */}
        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-3">
            <Target className="h-5 w-5 text-teal-600" />
            <span className={`${theme.fontSizeBase} font-semibold flex-1`}>
              {t(lang, "glucose_unit")}
            </span>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {([
              { v: "mg_dL", label: t(lang, "unit_mg") },
              { v: "mmol_L", label: t(lang, "unit_mmol") },
            ] as const).map((u) => (
              <button
                key={u.v}
                onClick={() => updateSettings({ unit: u.v as GlucoseUnit })}
                className={`py-2 rounded-xl border-2 text-sm font-semibold transition-all ${
                  settings.unit === u.v
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                    : `${theme.border} ${theme.textMuted}`
                }`}
              >
                {u.label}
              </button>
            ))}
          </div>
        </div>

        {/* ===== قسم الملف الشخصي ===== */}
        <SectionTitle icon={<User className="h-4 w-4" />} title={t(lang, "profile")} />

        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-3">
            <User className="h-5 w-5 text-teal-600" />
            <span className={`${theme.fontSizeBase} font-semibold flex-1`}>
              {t(lang, "name")}
            </span>
          </div>
          <div className="flex gap-2">
            <input
              value={nameDraft}
              onChange={(e) => setNameDraft(e.target.value)}
              className={`flex-1 px-3 py-2 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
            />
            <button
              onClick={saveName}
              className="px-4 py-2 rounded-xl bg-teal-600 text-white font-semibold"
            >
              {t(lang, "save")}
            </button>
          </div>
        </div>

        {/* ===== قسم التكاملات ===== */}
        <SectionTitle icon={<Bluetooth className="h-4 w-4" />} title={t(lang, "integrations")} />

        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
          <div className="flex items-center gap-3 mb-2">
            <div className="h-10 w-10 rounded-xl bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
              <Bluetooth className="h-5 w-5 text-slate-500" />
            </div>
            <div className="flex-1">
              <div className={`${theme.fontSizeBase} font-semibold`}>
                {t(lang, "device_integration")}
              </div>
              <div className={`${theme.fontSizeSm} ${theme.textMuted}`}>
                {t(lang, "coming_soon")}
              </div>
            </div>
            <span className="px-2.5 py-1 rounded-full bg-amber-100 dark:bg-amber-900/40 text-amber-700 dark:text-amber-300 text-xs font-bold">
              {t(lang, "coming_soon")}
            </span>
          </div>
          <div className={`mt-3 pt-3 border-t ${theme.border} flex items-start gap-2`}>
            <AlertCircle className="h-4 w-4 text-amber-500 flex-shrink-0 mt-0.5" />
            <p className={`${theme.fontSizeSm} ${theme.textMuted}`}>
              {t(lang, "coming_soon_desc")}
            </p>
          </div>
        </div>

        {/* ===== قسم حول التطبيق ===== */}
        <SectionTitle icon={<Info className="h-4 w-4" />} title={t(lang, "about")} />

        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding} flex items-center justify-between`}>
          <span className={`${theme.fontSizeBase}`}>{t(lang, "version")}</span>
          <span className={`${theme.fontSizeBase} ${theme.textMuted}`}>1.0.0 Prototype</span>
        </div>

        <AlertDialog>
          <AlertDialogTrigger asChild>
            <button
              className={`w-full ${theme.surface} ${theme.border} border-2 border-red-300 dark:border-red-900 ${theme.radius} ${theme.padding} flex items-center justify-center gap-2 text-red-600 dark:text-red-400 font-semibold`}
            >
              <RotateCcw className="h-5 w-5" />
              {t(lang, "reset_data")}
            </button>
          </AlertDialogTrigger>
          <AlertDialogContent>
            <AlertDialogHeader>
              <AlertDialogTitle>{t(lang, "reset_data")}</AlertDialogTitle>
              <AlertDialogDescription>
                {t(lang, "reset_confirm")}
              </AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t(lang, "cancel")}</AlertDialogCancel>
              <AlertDialogAction
                onClick={handleReset}
                className="bg-red-600 hover:bg-red-700 text-white"
              >
                {t(lang, "ok")}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </div>
  );
}

function SectionTitle({ icon, title }: { icon: React.ReactNode; title: string }) {
  const { settings } = useAppStore();
  const theme = themes[settings.theme];
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className={`flex items-center gap-2 ${theme.fontSizeSm} font-bold uppercase tracking-wide text-teal-600 dark:text-teal-400 pt-2`}
    >
      {icon}
      {title}
    </motion.div>
  );
}
