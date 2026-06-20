"use client";

import { useAppStore } from "@/lib/store";
import { PhoneFrame } from "@/components/phone/PhoneFrame";
import { BottomNav } from "@/components/phone/BottomNav";
import { Onboarding } from "@/components/screens/Onboarding";
import { Home } from "@/components/screens/Home";
import { AddReading } from "@/components/screens/AddReading";
import { Trends } from "@/components/screens/Trends";
import { Reminders } from "@/components/screens/Reminders";
import { Settings } from "@/components/screens/Settings";
import { AnimatePresence, motion } from "framer-motion";

export default function Page() {
  const { onboarded, activeScreen } = useAppStore();

  // إذا لم يكمل المستخدم الترحيب، اعرض شاشة الترحيب فقط
  if (!onboarded) {
    return (
      <PhoneFrame>
        <Onboarding />
      </PhoneFrame>
    );
  }

  // شاشة الإضافة تظهر كاملة بدون شريط سفلي (تشبه modal)
  if (activeScreen === "add") {
    return (
      <PhoneFrame>
        <AddReading />
      </PhoneFrame>
    );
  }

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
