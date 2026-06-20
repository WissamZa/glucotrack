"use client";

import { useEffect } from "react";
import { useAppStore } from "@/lib/store";
import { useSettings, useReadings, useReminders, useSeed } from "@/lib/api-hooks";
import { PhoneFrame } from "@/components/phone/PhoneFrame";
import { BottomNav } from "@/components/phone/BottomNav";
import { Onboarding } from "@/components/screens/Onboarding";
import { Home } from "@/components/screens/Home";
import { AddReading } from "@/components/screens/AddReading";
import { Trends } from "@/components/screens/Trends";
import { Reminders } from "@/components/screens/Reminders";
import { Settings } from "@/components/screens/Settings";
import { AnimatePresence, motion } from "framer-motion";
import { Loader2 } from "lucide-react";

export default function Page() {
  const settings = useAppStore((s) => s.settings);
  const onboarded = useAppStore((s) => s.onboarded);
  const activeScreen = useAppStore((s) => s.activeScreen);

  // ===== Bootstrap on first mount =====
  // 1) Seed the DB if empty (no-op if already populated)
  // 2) Fetch settings, readings, reminders
  const seedMut = useSeed();
  const settingsQ = useSettings();
  const readingsQ = useReadings();
  const remindersQ = useReminders();

  // Run seed once on mount
  useEffect(() => {
    seedMut.mutate();
  }, []);

  // Subscribe to readings/reminders queries so cache stays warm.
  // Their results sync into the Zustand store via the hooks' internal effects.
  void readingsQ.data;
  void remindersQ.data;

  // Set initial screen based on onboarded flag once settings arrive
  useEffect(() => {
    if (settings?.onboarded && onboarded === false) {
      useAppStore.setState({ onboarded: true, activeScreen: "home" });
    }
    if (settings && !settings.onboarded) {
      useAppStore.setState({ activeScreen: "onboarding" });
    }
  }, [settings, onboarded]);

  // ===== Loading state =====
  if (settingsQ.isLoading || !settings) {
    return (
      <PhoneFrame>
        <div className="h-full flex flex-col items-center justify-center gap-3 text-slate-500">
          <Loader2 className="h-8 w-8 animate-spin text-teal-600" />
          <p className="text-sm">جارٍ التحميل...</p>
        </div>
      </PhoneFrame>
    );
  }

  // ===== Onboarding (when not completed) =====
  if (!settings.onboarded) {
    return (
      <PhoneFrame>
        <Onboarding />
      </PhoneFrame>
    );
  }

  // ===== Add reading = full-screen modal =====
  if (activeScreen === "add") {
    return (
      <PhoneFrame>
        <AddReading />
      </PhoneFrame>
    );
  }

  // ===== Main app shell =====
  return (
    <PhoneFrame>
      <div className="h-full flex flex-col">
        <div className="flex-1 overflow-hidden">
          <AnimatePresence mode="wait">
            <motion.div
              key={activeScreen}
              initial={{ opacity: 0, x: 20 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -20 }}
              transition={{ duration: 0.2 }}
              className="h-full"
            >
              {activeScreen === "home" && <Home />}
              {activeScreen === "trends" && <Trends />}
              {activeScreen === "reminders" && <Reminders />}
              {activeScreen === "settings" && <Settings />}
            </motion.div>
          </AnimatePresence>
        </div>
        <BottomNav />
      </div>
    </PhoneFrame>
  );
}
