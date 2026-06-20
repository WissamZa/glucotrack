"use client";

import { create } from "zustand";
import type { Reading, Reminder, Settings, ScreenName } from "./types";

/**
 * App UI state store.
 * - Holds ONLY UI/navigation state + cached data shown to the user.
 * - All data is fetched from the SQLite-backed API via TanStack Query.
 * - Data actions live in `useDataActions()` (below) so components can
 *   mutate the DB and let React Query refetch.
 */

interface AppState {
  // Navigation
  activeScreen: ScreenName;
  setScreen: (s: ScreenName) => void;

  // Onboarding flag (mirrors settings.onboarded but kept here for fast access)
  onboarded: boolean;
  setOnboarded: (v: boolean) => void;

  // Cached data (hydrated by React Query on mount)
  settings: Settings | null;
  readings: Reading[];
  reminders: Reminder[];

  // Setters (called by React Query observers)
  setSettings: (s: Settings | null) => void;
  setReadings: (r: Reading[]) => void;
  setReminders: (r: Reminder[]) => void;

  // Convenience upsert helpers (used by mutations to update cache)
  upsertReading: (r: Reading) => void;
  removeReading: (id: string) => void;
  upsertReminder: (r: Reminder) => void;
  removeReminder: (id: string) => void;
}

export const useAppStore = create<AppState>()((set) => ({
  activeScreen: "onboarding",
  setScreen: (s) => set({ activeScreen: s }),

  onboarded: false,
  setOnboarded: (v) => set({ onboarded: v }),

  settings: null,
  readings: [],
  reminders: [],

  setSettings: (s) => set({ settings: s }),
  setReadings: (r) => set({ readings: r }),
  setReminders: (r) => set({ reminders: r }),

  upsertReading: (r) =>
    set((state) => {
      const exists = state.readings.some((x) => x.id === r.id);
      const next = exists
        ? state.readings.map((x) => (x.id === r.id ? r : x))
        : [r, ...state.readings];
      return {
        readings: next.sort((a, b) => b.timestamp - a.timestamp),
      };
    }),

  removeReading: (id) =>
    set((state) => ({
      readings: state.readings.filter((r) => r.id !== id),
    })),

  upsertReminder: (r) =>
    set((state) => {
      const exists = state.reminders.some((x) => x.id === r.id);
      const next = exists
        ? state.reminders.map((x) => (x.id === r.id ? r : x))
        : [...state.reminders, r];
      return {
        reminders: next.sort((a, b) => a.time.localeCompare(b.time)),
      };
    }),

  removeReminder: (id) =>
    set((state) => ({
      reminders: state.reminders.filter((r) => r.id !== id),
    })),
}));
