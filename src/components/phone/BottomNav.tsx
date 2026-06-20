"use client";

import { Home, TrendingUp, Bell, Settings as SettingsIcon, Plus } from "lucide-react";
import { useAppStore } from "@/lib/store";
import { themes, statusClasses } from "@/lib/themes";
import { t } from "@/lib/i18n";
import type { ScreenName } from "@/lib/types";
import { motion } from "framer-motion";

export function BottomNav() {
  const settings = useAppStore((s) => s.settings)!;
  const activeScreen = useAppStore((s) => s.activeScreen);
  const setScreen = useAppStore((s) => s.setScreen);
  const theme = themes[settings.theme];
  const lang = settings.language;

  const items: Array<{ key: ScreenName; icon: React.ReactNode; label: string }> = [
    { key: "home", icon: <Home className="h-5 w-5" />, label: t(lang, "nav_home") },
    { key: "trends", icon: <TrendingUp className="h-5 w-5" />, label: t(lang, "nav_trends") },
    { key: "add", icon: <Plus className="h-6 w-6" />, label: t(lang, "nav_add") },
    { key: "reminders", icon: <Bell className="h-5 w-5" />, label: t(lang, "nav_reminders") },
    { key: "settings", icon: <SettingsIcon className="h-5 w-5" />, label: t(lang, "nav_settings") },
  ];

  // النمط الودود لكبار السن: أزرار أكبر وتباين أعلى
  const isElder = settings.theme === "elder";
  const isModern = settings.theme === "modern";

  return (
    <nav
      className={`relative flex items-center justify-around px-2 pt-2 pb-3 border-t ${theme.border} ${
        isModern ? "bg-black/40 backdrop-blur-xl" : theme.surface
      }`}
    >
      {items.map((item) => {
        const isAdd = item.key === "add";
        const isActive = activeScreen === item.key;

        if (isAdd) {
          return (
            <button
              key={item.key}
              onClick={() => setScreen("add")}
              className="flex flex-col items-center -mt-6"
              aria-label={item.label}
            >
              <motion.div
                whileTap={{ scale: 0.9 }}
                className={`h-14 w-14 rounded-full ${theme.primary} ${theme.primaryText} flex items-center justify-center shadow-lg ${
                  isElder ? "ring-4 ring-slate-900 h-16 w-16" : ""
                }`}
              >
                {item.icon}
              </motion.div>
              <span className={`mt-1 ${theme.fontSizeSm} ${theme.textMuted}`}>
                {item.label}
              </span>
            </button>
          );
        }

        return (
          <button
            key={item.key}
            onClick={() => setScreen(item.key)}
            className={`flex flex-col items-center gap-1 px-3 py-1.5 rounded-xl transition-colors ${
              isActive
                ? isModern
                  ? "text-cyan-300"
                  : "text-teal-600"
                : theme.textMuted
            }`}
            aria-label={item.label}
          >
            <div className={`${isElder ? "scale-125" : ""} transition-transform`}>
              {item.icon}
            </div>
            <span className={`${theme.fontSizeSm} font-medium`}>{item.label}</span>
            {isActive && (
              <motion.div
                layoutId="active-dot"
                className={`h-1 w-6 rounded-full ${
                  isModern ? "bg-cyan-400" : "bg-teal-600"
                }`}
              />
            )}
          </button>
        );
      })}
    </nav>
  );
}
