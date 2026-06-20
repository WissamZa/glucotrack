"use client";

import { useEffect } from "react";
import { useAppStore } from "@/lib/store";
import { themes } from "@/lib/themes";
import { t } from "@/lib/i18n";

interface PhoneFrameProps {
  children: React.ReactNode;
}

export function PhoneFrame({ children }: PhoneFrameProps) {
  const settings = useAppStore((s) => s.settings);
  const fallbackLang = "ar";
  const fallbackTheme = "classic";
  const lang = settings?.language ?? fallbackLang;
  const themeName = settings?.theme ?? fallbackTheme;
  const theme = themes[themeName];
  const isRTL = lang === "ar";

  // تحديث اتجاه الصفحة واللغة عند تغيير الإعدادات
  useEffect(() => {
    document.documentElement.lang = lang;
    document.documentElement.dir = isRTL ? "rtl" : "ltr";
  }, [lang, isRTL]);

  return (
    <div className="min-h-screen w-full bg-gradient-to-br from-slate-200 via-slate-100 to-slate-300 dark:from-slate-900 dark:to-slate-800 flex items-center justify-center p-4 sm:p-6">
      <div className="w-full max-w-[420px]">
        {/* عنوان بريدي فوق الهاتف */}
        <div className="text-center mb-4 hidden sm:block">
          <h1 className="text-2xl font-bold text-slate-800 dark:text-slate-100">
            {t(lang, "app_name")}
          </h1>
          <p className="text-sm text-slate-600 dark:text-slate-400">
            {t(lang, "app_tagline")} · SQLite + Google Drive Sync
          </p>
        </div>

        {/* إطار الهاتف */}
        <div className="relative mx-auto bg-slate-950 rounded-[2.75rem] p-2.5 shadow-2xl shadow-slate-900/40 ring-1 ring-slate-800/50">
          {/* الشاشة */}
          <div
            className={`relative overflow-hidden rounded-[2.25rem] ${theme.bg} ${theme.text}`}
            style={{
              height: "min(720px, calc(100vh - 6rem))",
              minHeight: "580px",
            }}
          >
            {/* النتوء العلوي (Notch / Dynamic Island) */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 z-50 w-32 h-6 bg-slate-950 rounded-b-2xl pointer-events-none" />

            {/* المحتوى */}
            <div className="h-full flex flex-col">{children}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
