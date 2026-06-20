"use client";

import { useState, useRef } from "react";
import { useAppStore } from "@/lib/store";
import {
  useUpdateSettings,
  useSyncStatus,
  useSyncConfig,
  useConnectDrive,
  useDisconnectDrive,
  useUploadToDrive,
  useDownloadFromDrive,
  downloadLocalBackup,
  useImportLocalBackup,
} from "@/lib/api-hooks";
import { themes } from "@/lib/themes";
import { t } from "@/lib/i18n";
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
  Cloud,
  CloudUpload,
  CloudDownload,
  Upload,
  Download,
  Loader2,
  CloudOff,
  RefreshCw,
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
import type { Language, ThemeStyle, DiabetesType, GlucoseUnit } from "@/lib/types";

export function Settings() {
  const settings = useAppStore((s) => s.settings);
  const updateSettings = useUpdateSettings();
  const { toast } = useToast();
  const [nameDraft, setNameDraft] = useState(settings?.userName ?? "");

  if (!settings) return null;

  const lang = settings.language;
  const theme = themes[settings.theme];
  const isRTL = lang === "ar";

  const handleReset = () => {
    updateSettings.mutate({ onboarded: false, userName: "" });
    toast({ title: t(lang, "reset_done") });
  };

  const saveName = () => {
    updateSettings.mutate({ userName: nameDraft.trim() || settings.userName });
    toast({ title: t(lang, "save_settings") });
  };

  return (
    <div className="h-full flex flex-col">
      <header className="px-5 pt-8 pb-3">
        <h1 className={`${theme.fontSize2xl} font-bold`}>{t(lang, "settings")}</h1>
      </header>

      <div className="flex-1 overflow-y-auto px-5 pb-4 space-y-4">
        <SectionTitle icon={<Palette className="h-4 w-4" />} title={t(lang, "appearance")} />

        {/* اللغة */}
        <SettingCard icon={<Globe className="h-5 w-5 text-teal-600" />} title={t(lang, "language")}>
          <div className="grid grid-cols-2 gap-2">
            {([
              { v: "ar", label: "العربية", flag: "🇸🇦" },
              { v: "en", label: "English", flag: "🇬🇧" },
            ] as const).map((l) => (
              <button
                key={l.v}
                onClick={() => updateSettings.mutate({ language: l.v as Language })}
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
        </SettingCard>

        {/* النمط */}
        <SettingCard icon={<Palette className="h-5 w-5 text-teal-600" />} title={t(lang, "display_style")}>
          <div className="space-y-2">
            {([
              { v: "classic", icon: <Stethoscope className="h-4 w-4" />, label: t(lang, "style_classic") },
              { v: "modern", icon: <Moon className="h-4 w-4" />, label: t(lang, "style_modern") },
              { v: "elder", icon: <Sun className="h-4 w-4" />, label: t(lang, "style_elder") },
            ] as const).map((s) => (
              <button
                key={s.v}
                onClick={() => updateSettings.mutate({ theme: s.v as ThemeStyle })}
                className={`w-full py-2.5 px-3 rounded-xl border-2 flex items-center gap-3 transition-all ${
                  settings.theme === s.v ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30" : theme.border
                }`}
              >
                <span className={settings.theme === s.v ? "text-teal-600" : theme.textMuted}>{s.icon}</span>
                <span className={`${theme.fontSizeBase} font-medium flex-1 text-start`}>{s.label}</span>
                {settings.theme === s.v && <Check className="h-4 w-4 text-teal-600" />}
              </button>
            ))}
          </div>
        </SettingCard>

        <SectionTitle icon={<HeartPulse className="h-4 w-4" />} title={t(lang, "health")} />

        {/* نوع السكري */}
        <SettingCard icon={<HeartPulse className="h-5 w-5 text-teal-600" />} title={t(lang, "diabetes_type")}>
          <div className="grid grid-cols-3 gap-2">
            {([
              { v: "type1", label: t(lang, "diabetes_type1") },
              { v: "type2", label: t(lang, "diabetes_type2") },
              { v: "gestational", label: t(lang, "diabetes_gestational") },
            ] as const).map((d) => (
              <button
                key={d.v}
                onClick={() => updateSettings.mutate({ diabetesType: d.v as DiabetesType })}
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
        </SettingCard>

        {/* النطاق المستهدف */}
        <SettingCard icon={<Target className="h-5 w-5 text-teal-600" />} title={`${t(lang, "glucose_targets")} (mg/dL)`}>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className={`${theme.fontSizeSm} ${theme.textMuted} block mb-1`}>{t(lang, "target_min")}</label>
              <input
                type="number"
                value={settings.targetMin}
                onChange={(e) =>
                  updateSettings.mutate({
                    targetMin: Math.max(40, Math.min(150, parseInt(e.target.value) || 80)),
                  })
                }
                className={`w-full px-3 py-2 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
              />
            </div>
            <div>
              <label className={`${theme.fontSizeSm} ${theme.textMuted} block mb-1`}>{t(lang, "target_max")}</label>
              <input
                type="number"
                value={settings.targetMax}
                onChange={(e) =>
                  updateSettings.mutate({
                    targetMax: Math.max(120, Math.min(300, parseInt(e.target.value) || 180)),
                  })
                }
                className={`w-full px-3 py-2 rounded-xl border-2 ${theme.border} ${theme.surface} ${theme.text} focus:outline-none focus:border-teal-600`}
              />
            </div>
          </div>
        </SettingCard>

        {/* وحدة القياس */}
        <SettingCard icon={<Target className="h-5 w-5 text-teal-600" />} title={t(lang, "glucose_unit")}>
          <div className="grid grid-cols-2 gap-2">
            {([
              { v: "mg_dL", label: t(lang, "unit_mg") },
              { v: "mmol_L", label: t(lang, "unit_mmol") },
            ] as const).map((u) => (
              <button
                key={u.v}
                onClick={() => updateSettings.mutate({ unit: u.v as GlucoseUnit })}
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
        </SettingCard>

        <SectionTitle icon={<User className="h-4 w-4" />} title={t(lang, "profile")} />

        <SettingCard icon={<User className="h-5 w-5 text-teal-600" />} title={t(lang, "name")}>
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
        </SettingCard>

        {/* ===== قسم المزامنة (Google Drive + Backup) ===== */}
        <SectionTitle icon={<Cloud className="h-4 w-4" />} title={t(lang, "integrations")} />

        <SyncSection />

        {/* ===== قسم التكاملات الأخرى ===== */}
        <SettingCard icon={<Bluetooth className="h-5 w-5 text-slate-500" />} title={t(lang, "device_integration")}>
          <div className="flex items-center justify-between mb-2">
            <span className={`${theme.fontSizeSm} ${theme.textMuted}`}>
              {t(lang, "coming_soon")}
            </span>
            <span className="px-2.5 py-1 rounded-full bg-amber-100 dark:bg-amber-900/40 text-amber-700 dark:text-amber-300 text-xs font-bold">
              {t(lang, "coming_soon")}
            </span>
          </div>
          <div className={`mt-3 pt-3 border-t ${theme.border} flex items-start gap-2`}>
            <AlertCircle className="h-4 w-4 text-amber-500 flex-shrink-0 mt-0.5" />
            <p className={`${theme.fontSizeSm} ${theme.textMuted}`}>{t(lang, "coming_soon_desc")}</p>
          </div>
        </SettingCard>

        {/* ===== قسم حول التطبيق ===== */}
        <SectionTitle icon={<Info className="h-4 w-4" />} title={t(lang, "about")} />

        <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding} flex items-center justify-between`}>
          <span className={`${theme.fontSizeBase}`}>{t(lang, "version")}</span>
          <span className={`${theme.fontSizeBase} ${theme.textMuted}`}>1.0.0 (SQLite + Drive Sync)</span>
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
              <AlertDialogDescription>{t(lang, "reset_confirm")}</AlertDialogDescription>
            </AlertDialogHeader>
            <AlertDialogFooter>
              <AlertDialogCancel>{t(lang, "cancel")}</AlertDialogCancel>
              <AlertDialogAction onClick={handleReset} className="bg-red-600 hover:bg-red-700 text-white">
                {t(lang, "ok")}
              </AlertDialogAction>
            </AlertDialogFooter>
          </AlertDialogContent>
        </AlertDialog>
      </div>
    </div>
  );
}

// =====================================
// Sync Section — Google Drive + Local
// =====================================
function SyncSection() {
  const settings = useAppStore((s) => s.settings);
  const { toast } = useToast();
  const syncStatusQ = useSyncStatus();
  const syncConfigQ = useSyncConfig();
  const connectMut = useConnectDrive();
  const disconnectMut = useDisconnectDrive();
  const uploadMut = useUploadToDrive();
  const downloadMut = useDownloadFromDrive();
  const importMut = useImportLocalBackup();
  const fileInputRef = useRef<HTMLInputElement>(null);

  if (!settings) return null;
  const lang = settings.language;
  const theme = themes[settings.theme];

  const state = syncStatusQ.data?.state;
  const clientId = syncConfigQ.data?.googleClientId || "";
  const scope = syncConfigQ.data?.scope || "https://www.googleapis.com/auth/drive.appdata";

  // ===== Handle Google Identity Services token =====
  // Each user signs in with THEIR OWN Google account.
  // The GOOGLE_CLIENT_ID identifies the app to Google — not the user.
  // The user's data goes to THEIR own Google Drive (appDataFolder).
  const handleConnectDrive = () => {
    if (!clientId) {
      toast({
        title: lang === "ar" ? "Google Client ID غير مُعد" : "Google Client ID not configured",
        description:
          lang === "ar"
            ? "المطور: أضف GOOGLE_CLIENT_ID في .env ثم أعد التشغيل. سيظل كل مستخدم يستخدم حسابه الخاص في Google Drive."
            : "Developer: Add GOOGLE_CLIENT_ID to .env then restart. Each user still uses their own Google account.",
        variant: "destructive",
      });
      return;
    }

    // Load Google Identity Services script
    const existing = document.getElementById("google-gis-script");
    if (!existing) {
      const script = document.createElement("script");
      script.id = "google-gis-script";
      script.src = "https://accounts.google.com/gsi/client";
      script.async = true;
      script.defer = true;
      script.onload = () => initTokenClient();
      document.head.appendChild(script);
    } else {
      initTokenClient();
    }

    function initTokenClient() {
      // @ts-expect-error - GIS is loaded externally
      const google = window.google;
      if (!google?.accounts?.oauth2) {
        toast({
          title: lang === "ar" ? "تعذّر تحميل Google" : "Failed to load Google",
          variant: "destructive",
        });
        return;
      }

      const tokenClient = google.accounts.oauth2.initTokenClient({
        client_id: clientId,
        scope,
        callback: (response: { access_token?: string }) => {
          if (response.access_token) {
            connectMut.mutate(response.access_token, {
              onSuccess: () =>
                toast({ title: lang === "ar" ? "تم الربط بنجاح" : "Connected successfully" }),
              onError: () =>
                toast({
                  title: lang === "ar" ? "فشل الربط" : "Connection failed",
                  variant: "destructive",
                }),
            });
          }
        },
      });
      tokenClient.requestAccessToken();
    }
  };

  const handleUpload = () => {
    uploadMut.mutate(undefined, {
      onSuccess: (data) =>
        toast({
          title: lang === "ar" ? "تم الرفع" : "Uploaded",
          description:
            lang === "ar"
              ? `${data.counts?.readings ?? 0} قراءة، ${data.counts?.reminders ?? 0} تذكير`
              : `${data.counts?.readings ?? 0} readings, ${data.counts?.reminders ?? 0} reminders`,
        }),
      onError: (e) =>
        toast({
          title: lang === "ar" ? "فشل الرفع" : "Upload failed",
          description: e.message,
          variant: "destructive",
        }),
    });
  };

  const handleDownload = () => {
    downloadMut.mutate(undefined, {
      onSuccess: (data) =>
        toast({
          title: lang === "ar" ? "تم التنزيل والدمج" : "Downloaded & merged",
          description:
            lang === "ar"
              ? `${data.merged?.readings ?? 0} قراءة، ${data.merged?.reminders ?? 0} تذكير`
              : `${data.merged?.readings ?? 0} readings, ${data.merged?.reminders ?? 0} reminders`,
        }),
      onError: (e) =>
        toast({
          title: lang === "ar" ? "فشل التنزيل" : "Download failed",
          description: e.message,
          variant: "destructive",
        }),
    });
  };

  const handleDisconnect = () => {
    disconnectMut.mutate(undefined, {
      onSuccess: () =>
        toast({ title: lang === "ar" ? "تم فصل الحساب" : "Disconnected" }),
    });
  };

  const handleExportLocal = () => {
    downloadLocalBackup();
    toast({ title: lang === "ar" ? "تم تنزيل النسخة" : "Backup downloaded" });
  };

  const handleImportLocal = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    importMut.mutate(file, {
      onSuccess: (data) =>
        toast({
          title: lang === "ar" ? "تم الاستيراد" : "Imported",
          description:
            lang === "ar"
              ? `${data.merged?.readings ?? 0} قراءة، ${data.merged?.reminders ?? 0} تذكير`
              : `${data.merged?.readings ?? 0} readings, ${data.merged?.reminders ?? 0} reminders`,
        }),
      onError: () =>
        toast({
          title: lang === "ar" ? "فشل الاستيراد" : "Import failed",
          variant: "destructive",
        }),
    });
    e.target.value = "";
  };

  const isBusy = uploadMut.isPending || downloadMut.isPending;
  const lastSync = state?.lastSyncAt ? new Date(state.lastSyncAt) : null;
  const lastSyncStr = lastSync?.toLocaleString(lang === "ar" ? "ar-EG" : "en-US", {
    dateStyle: "short",
    timeStyle: "short",
  });

  return (
    <>
      {/* ===== Google Drive Card ===== */}
      <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
        <div className="flex items-center gap-3 mb-3">
          <div className="h-10 w-10 rounded-xl bg-gradient-to-br from-blue-500 to-green-500 flex items-center justify-center">
            <Cloud className="h-5 w-5 text-white" />
          </div>
          <div className="flex-1">
            <div className={`${theme.fontSizeBase} font-semibold flex items-center gap-2`}>
              Google Drive
              {state?.connected && (
                <span className="px-1.5 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-900/40 text-emerald-700 dark:text-emerald-300 text-[10px] font-bold">
                  {lang === "ar" ? "متصل" : "Connected"}
                </span>
              )}
            </div>
            <div className={`${theme.fontSizeSm} ${theme.textMuted}`}>
              {state?.connected ? (
                <>
                  {t(lang, "drive_connected_as")} <span className="font-semibold">{state.accountEmail}</span>
                </>
              ) : (
                t(lang, "google_signin_desc")
              )}
            </div>
          </div>
        </div>

        {/* Sync status row */}
        {(state?.lastSyncAt || state?.lastSyncError) && (
          <div className={`mb-3 p-2.5 rounded-lg ${theme.surfaceAlt} ${theme.fontSizeSm} flex items-center gap-2`}>
            {state.lastSyncStatus === "success" && <Check className="h-4 w-4 text-emerald-500" />}
            {state.lastSyncStatus === "failed" && <AlertCircle className="h-4 w-4 text-red-500" />}
            {state.lastSyncStatus === "in_progress" && <Loader2 className="h-4 w-4 animate-spin text-teal-600" />}
            <span className={theme.textMuted}>
              {state.lastSyncStatus === "in_progress"
                ? lang === "ar"
                  ? "جارٍ المزامنة..."
                  : "Syncing..."
                : lang === "ar"
                  ? `آخر مزامنة: ${lastSyncStr}`
                  : `Last sync: ${lastSyncStr}`}
              {state.lastSyncError && ` · ${state.lastSyncError}`}
            </span>
          </div>
        )}

        {/* Actions */}
        {!state?.connected ? (
          <button
            onClick={handleConnectDrive}
            disabled={connectMut.isPending}
            className="w-full py-2.5 rounded-xl bg-gradient-to-r from-blue-500 to-green-500 text-white font-bold flex items-center justify-center gap-2 disabled:opacity-50 active:scale-95 transition-transform"
          >
            {connectMut.isPending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Cloud className="h-4 w-4" />
            )}
            {connectMut.isPending
              ? t(lang, "signing_in")
              : t(lang, "google_signin")}
          </button>
        ) : (
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={handleUpload}
              disabled={isBusy}
              className="py-2.5 rounded-xl bg-teal-600 text-white font-semibold flex items-center justify-center gap-2 disabled:opacity-50 active:scale-95 transition-transform"
            >
              {uploadMut.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <CloudUpload className="h-4 w-4" />
              )}
              {lang === "ar" ? "رفع" : "Upload"}
            </button>
            <button
              onClick={handleDownload}
              disabled={isBusy}
              className="py-2.5 rounded-xl bg-slate-700 dark:bg-slate-200 text-white dark:text-slate-900 font-semibold flex items-center justify-center gap-2 disabled:opacity-50 active:scale-95 transition-transform"
            >
              {downloadMut.isPending ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <CloudDownload className="h-4 w-4" />
              )}
              {lang === "ar" ? "تنزيل" : "Download"}
            </button>
            <button
              onClick={handleDisconnect}
              disabled={isBusy}
              className="col-span-2 py-2 rounded-xl border-2 border-red-300 dark:border-red-900 text-red-600 dark:text-red-400 text-sm font-semibold flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <CloudOff className="h-4 w-4" />
              {t(lang, "signout")}
            </button>
          </div>
        )}

        {/* Helper note */}
        <div className={`mt-3 pt-3 border-t ${theme.border} flex items-start gap-2`}>
          <Info className="h-3.5 w-3.5 text-slate-400 flex-shrink-0 mt-0.5" />
          <p className={`${theme.fontSizeSm} ${theme.textMuted} leading-relaxed`}>
            {t(lang, "your_data_your_account")}
            {" · "}
            {lang === "ar"
              ? "تُحفظ البيانات في مجلد مخفي خاص بالتطبيق (appDataFolder) ولا يمكن للتطبيق الوصول لملفاتك الأخرى في Drive."
              : "Data is stored in a hidden app-scoped folder (appDataFolder). The app cannot access your other Drive files."}
          </p>
        </div>
      </div>

      {/* ===== Local Backup (no Google needed) ===== */}
      <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
        <div className="flex items-center gap-3 mb-3">
          <div className="h-10 w-10 rounded-xl bg-slate-200 dark:bg-slate-700 flex items-center justify-center">
            <RefreshCw className="h-5 w-5 text-slate-600 dark:text-slate-300" />
          </div>
          <div className="flex-1">
            <div className={`${theme.fontSizeBase} font-semibold`}>
              {lang === "ar" ? "نسخ احتياطي محلي" : "Local Backup"}
            </div>
            <div className={`${theme.fontSizeSm} ${theme.textMuted}`}>
              {lang === "ar"
                ? "صدّر بياناتك كملف JSON بدون إنترنت"
                : "Export your data as a JSON file (offline)"}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={handleExportLocal}
            className="py-2.5 rounded-xl bg-teal-600 text-white font-semibold flex items-center justify-center gap-2 active:scale-95 transition-transform"
          >
            <Upload className="h-4 w-4" />
            {lang === "ar" ? "تصدير" : "Export"}
          </button>
          <button
            onClick={() => fileInputRef.current?.click()}
            disabled={importMut.isPending}
            className="py-2.5 rounded-xl bg-slate-700 dark:bg-slate-200 text-white dark:text-slate-900 font-semibold flex items-center justify-center gap-2 disabled:opacity-50 active:scale-95 transition-transform"
          >
            {importMut.isPending ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Download className="h-4 w-4" />
            )}
            {lang === "ar" ? "استيراد" : "Import"}
          </button>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="application/json"
          onChange={handleImportLocal}
          className="hidden"
        />
      </div>
    </>
  );
}

function SettingCard({
  icon,
  title,
  children,
}: {
  icon: React.ReactNode;
  title: string;
  children: React.ReactNode;
}) {
  const settings = useAppStore((s) => s.settings)!;
  const theme = themes[settings.theme];
  return (
    <div className={`${theme.surface} ${theme.border} border ${theme.radius} ${theme.padding}`}>
      <div className="flex items-center gap-3 mb-3">
        {icon}
        <span className={`${theme.fontSizeBase} font-semibold flex-1`}>{title}</span>
      </div>
      {children}
    </div>
  );
}

function SectionTitle({ icon, title }: { icon: React.ReactNode; title: string }) {
  const settings = useAppStore((s) => s.settings)!;
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
