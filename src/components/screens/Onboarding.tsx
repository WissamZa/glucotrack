"use client";

import { useState } from "react";
import { useUpdateSettings } from "@/lib/api-hooks";
import { t } from "@/lib/i18n";
import { motion } from "framer-motion";
import { Activity, Moon, Sun, HeartPulse, Check, Stethoscope } from "lucide-react";
import type { Language, ThemeStyle, DiabetesType } from "@/lib/types";

export function Onboarding() {
  const updateSettings = useUpdateSettings();
  const [step, setStep] = useState(0);
  const [lang, setLang] = useState<Language>("ar");
  const [style, setStyle] = useState<ThemeStyle>("classic");
  const [name, setName] = useState("");
  const [dtype, setDtype] = useState<DiabetesType>("type2");

  const next = () => setStep((s) => s + 1);
  const prev = () => setStep((s) => Math.max(0, s - 1));

  const finish = () => {
    updateSettings.mutate({
      language: lang,
      theme: style,
      userName: name.trim() || (lang === "ar" ? "صديقي" : "Friend"),
      diabetesType: dtype,
      onboarded: true,
    });
  };

  return (
    <div className="h-full flex flex-col bg-gradient-to-b from-teal-50 via-white to-teal-50 dark:from-slate-900 dark:to-slate-950 text-slate-900 dark:text-white">
      {/* Progress dots */}
      <div className="flex justify-center gap-2 pt-8 pb-2">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className={`h-2 rounded-full transition-all ${
              i === step ? "w-8 bg-teal-600" : "w-2 bg-slate-300"
            }`}
          />
        ))}
      </div>

      <div className="flex-1 overflow-y-auto px-6 py-4">
        {step === 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="h-full flex flex-col items-center text-center"
          >
            <div className="mt-6 mb-8">
              <motion.div
                animate={{ scale: [1, 1.05, 1] }}
                transition={{ duration: 2, repeat: Infinity }}
                className="h-28 w-28 rounded-full bg-gradient-to-br from-teal-500 to-emerald-500 flex items-center justify-center shadow-xl shadow-teal-500/30"
              >
                <HeartPulse className="h-14 w-14 text-white" />
              </motion.div>
            </div>
            <h1 className="text-3xl font-bold mb-2">{t(lang, "app_name")}</h1>
            <p className="text-slate-500 dark:text-slate-400 mb-10">
              {t(lang, "app_tagline")}
            </p>

            <h2 className="text-lg font-semibold mb-4">{t(lang, "choose_language")}</h2>
            <div className="grid grid-cols-2 gap-3 w-full max-w-sm">
              <button
                onClick={() => setLang("ar")}
                className={`p-5 rounded-2xl border-2 transition-all ${
                  lang === "ar"
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30"
                    : "border-slate-200 dark:border-slate-700"
                }`}
              >
                <div className="text-3xl mb-1">🇸🇦</div>
                <div className="font-bold">العربية</div>
              </button>
              <button
                onClick={() => setLang("en")}
                className={`p-5 rounded-2xl border-2 transition-all ${
                  lang === "en"
                    ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30"
                    : "border-slate-200 dark:border-slate-700"
                }`}
              >
                <div className="text-3xl mb-1">🇬🇧</div>
                <div className="font-bold">English</div>
              </button>
            </div>
          </motion.div>
        )}

        {step === 1 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="h-full flex flex-col"
          >
            <h2 className="text-2xl font-bold mb-2 text-center">{t(lang, "choose_style")}</h2>
            <p className="text-slate-500 dark:text-slate-400 text-center mb-6 text-sm">
              {lang === "ar" ? "يمكنك تغييره لاحقاً من الإعدادات" : "You can change it later in settings"}
            </p>

            <div className="space-y-3">
              <StyleCard
                active={style === "classic"}
                onClick={() => setStyle("classic")}
                icon={<Stethoscope className="h-6 w-6" />}
                title={t(lang, "style_classic")}
                desc={t(lang, "style_classic_desc")}
                preview="classic"
              />
              <StyleCard
                active={style === "modern"}
                onClick={() => setStyle("modern")}
                icon={<Moon className="h-6 w-6" />}
                title={t(lang, "style_modern")}
                desc={t(lang, "style_modern_desc")}
                preview="modern"
              />
              <StyleCard
                active={style === "elder"}
                onClick={() => setStyle("elder")}
                icon={<Sun className="h-6 w-6" />}
                title={t(lang, "style_elder")}
                desc={t(lang, "style_elder_desc")}
                preview="elder"
              />
            </div>
          </motion.div>
        )}

        {step === 2 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="h-full flex flex-col"
          >
            <div className="text-center mb-6">
              <div className="h-16 w-16 rounded-2xl bg-teal-100 dark:bg-teal-900/40 flex items-center justify-center mx-auto mb-3">
                <Activity className="h-8 w-8 text-teal-600" />
              </div>
              <h2 className="text-2xl font-bold mb-1">{t(lang, "welcome")}</h2>
              <p className="text-slate-500 dark:text-slate-400 text-sm">
                {lang === "ar" ? "لنخصص تجربتك" : "Let's personalize your experience"}
              </p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-semibold mb-2 text-slate-700 dark:text-slate-300">
                  {t(lang, "your_name")}
                </label>
                <input
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder={lang === "ar" ? "اكتب اسمك" : "Enter your name"}
                  className="w-full px-4 py-3 rounded-2xl border-2 border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 focus:outline-none focus:border-teal-600"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold mb-2 text-slate-700 dark:text-slate-300">
                  {t(lang, "your_diabetes_type")}
                </label>
                <div className="grid grid-cols-3 gap-2">
                  {([
                    { v: "type1", label: t(lang, "diabetes_type1") },
                    { v: "type2", label: t(lang, "diabetes_type2") },
                    { v: "gestational", label: t(lang, "diabetes_gestational") },
                  ] as const).map((d) => (
                    <button
                      key={d.v}
                      onClick={() => setDtype(d.v)}
                      className={`px-3 py-3 rounded-xl border-2 text-sm font-semibold transition-all ${
                        dtype === d.v
                          ? "border-teal-600 bg-teal-50 dark:bg-teal-900/30 text-teal-700 dark:text-teal-300"
                          : "border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-400"
                      }`}
                    >
                      {d.label}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </div>

      {/* Footer buttons */}
      <div className="px-6 py-5 flex gap-3 border-t border-slate-100 dark:border-slate-800">
        {step > 0 && (
          <button
            onClick={prev}
            className="px-5 py-3 rounded-2xl border-2 border-slate-200 dark:border-slate-700 font-semibold text-slate-700 dark:text-slate-300"
          >
            {t(lang, "back")}
          </button>
        )}
        <button
          onClick={step === 2 ? finish : next}
          className="flex-1 py-3 rounded-2xl bg-teal-600 text-white font-bold shadow-lg shadow-teal-600/30 flex items-center justify-center gap-2 active:scale-95 transition-transform"
        >
          {step === 2 ? (
            <>
              {t(lang, "get_started")} <Check className="h-5 w-5" />
            </>
          ) : (
            t(lang, "get_started")
          )}
        </button>
      </div>
    </div>
  );
}

function StyleCard({
  active,
  onClick,
  icon,
  title,
  desc,
  preview,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  title: string;
  desc: string;
  preview: "classic" | "modern" | "elder";
}) {
  return (
    <button
      onClick={onClick}
      className={`w-full p-4 rounded-2xl border-2 transition-all flex items-center gap-4 text-left ${
        active ? "border-teal-600 bg-teal-50 dark:bg-teal-900/20" : "border-slate-200 dark:border-slate-700"
      }`}
    >
      <div
        className={`h-14 w-14 rounded-xl flex items-center justify-center flex-shrink-0 ${
          preview === "classic"
            ? "bg-white border border-slate-200 text-teal-600"
            : preview === "modern"
              ? "bg-gradient-to-br from-fuchsia-500 to-cyan-400 text-white"
              : "bg-slate-900 text-white"
        }`}
      >
        {icon}
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-bold">{title}</div>
        <div className="text-sm text-slate-500 dark:text-slate-400">{desc}</div>
      </div>
      {active && (
        <div className="h-6 w-6 rounded-full bg-teal-600 flex items-center justify-center flex-shrink-0">
          <Check className="h-4 w-4 text-white" />
        </div>
      )}
    </button>
  );
}
