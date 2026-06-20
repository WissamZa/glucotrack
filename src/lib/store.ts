"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type {
  Reading,
  Reminder,
  Settings,
  ScreenName,
  Language,
  ThemeStyle,
} from "./types";
import { defaultSettings, seedReadings, seedReminders } from "./seed";

interface AppState {
  // Onboarding
  onboarded: boolean;
  // Navigation
  activeScreen: ScreenName;
  // Data
  readings: Reading[];
  reminders: Reminder[];
  settings: Settings;
  // Actions
  setScreen: (s: ScreenName) => void;
  completeOnboarding: (s: Partial<Settings>) => void;
  addReading: (r: Omit<Reading, "id">) => void;
  deleteReading: (id: string) => void;
  addReminder: (r: Omit<Reminder, "id">) => void;
  toggleReminder: (id: string) => void;
  deleteReminder: (id: string) => void;
  updateSettings: (s: Partial<Settings>) => void;
  setLanguage: (l: Language) => void;
  setTheme: (t: ThemeStyle) => void;
  resetAll: () => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set) => ({
      onboarded: false,
      activeScreen: "onboarding",
      readings: seedReadings,
      reminders: seedReminders,
      settings: defaultSettings,

      setScreen: (s) => set({ activeScreen: s }),

      completeOnboarding: (s) =>
        set((state) => ({
          onboarded: true,
          activeScreen: "home",
          settings: { ...state.settings, ...s },
        })),

      addReading: (r) =>
        set((state) => ({
          readings: [
            { ...r, id: `r-${Date.now()}-${Math.random().toString(36).slice(2, 7)}` },
            ...state.readings,
          ].sort((a, b) => b.timestamp - a.timestamp),
        })),

      deleteReading: (id) =>
        set((state) => ({
          readings: state.readings.filter((r) => r.id !== id),
        })),

      addReminder: (r) =>
        set((state) => ({
          reminders: [
            ...state.reminders,
            { ...r, id: `rem-${Date.now()}-${Math.random().toString(36).slice(2, 7)}` },
          ],
        })),

      toggleReminder: (id) =>
        set((state) => ({
          reminders: state.reminders.map((r) =>
            r.id === id ? { ...r, enabled: !r.enabled } : r,
          ),
        })),

      deleteReminder: (id) =>
        set((state) => ({
          reminders: state.reminders.filter((r) => r.id !== id),
        })),

      updateSettings: (s) =>
        set((state) => ({
          settings: { ...state.settings, ...s },
        })),

      setLanguage: (l) =>
        set((state) => ({ settings: { ...state.settings, language: l } })),

      setTheme: (t) =>
        set((state) => ({ settings: { ...state.settings, theme: t } })),

      resetAll: () =>
        set({
          onboarded: false,
          activeScreen: "onboarding",
          readings: seedReadings,
          reminders: seedReminders,
          settings: defaultSettings,
        }),
    }),
    {
      name: "glucotrack-prototype",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
