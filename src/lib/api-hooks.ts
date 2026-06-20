"use client";

import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { useAppStore } from "./store";
import type { Reading, Reminder, Settings, ReadingType } from "./types";

// ===== Query keys =====
export const KEYS = {
  readings: ["readings"] as const,
  reminders: ["reminders"] as const,
  settings: ["settings"] as const,
  syncStatus: ["sync-status"] as const,
  syncConfig: ["sync-config"] as const,
};

// ===== Helpers =====
async function fetchJSON<T>(url: string, init?: RequestInit): Promise<T> {
  const res = await fetch(url, init);
  if (!res.ok) throw new Error(`${url} ${res.status}`);
  return res.json() as Promise<T>;
}

// ===== Readings =====
// The API returns `timestamp` as an ISO string. We normalize to a number
// (ms since epoch) so downstream code can do numeric comparisons.
function normalizeReading(r: any): Reading {
  return {
    ...r,
    timestamp: typeof r.timestamp === "string" ? new Date(r.timestamp).getTime() : r.timestamp,
  };
}

export function useReadings() {
  const setReadings = useAppStore((s) => s.setReadings);
  const q = useQuery({
    queryKey: KEYS.readings,
    queryFn: async () => {
      const data = await fetchJSON<{ readings: any[] }>("/api/readings");
      return { readings: data.readings.map(normalizeReading) };
    },
    staleTime: 30_000,
  });

  // Sync to store
  useEffect(() => {
    if (q.data?.readings) {
      setReadings(q.data.readings);
    }
  }, [q.data, setReadings]);

  return q;
}

export function useAddReading() {
  const qc = useQueryClient();
  const upsert = useAppStore((s) => s.upsertReading);
  return useMutation({
    mutationFn: async (input: {
      value: number;
      type: ReadingType;
      timestamp: number;
      notes?: string;
      carbs?: number;
      insulin?: number;
    }) => {
      const res = await fetch("/api/readings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });
      if (!res.ok) throw new Error("failed");
      const data = await res.json();
      return normalizeReading(data.reading);
    },
    onSuccess: (reading) => {
      upsert(reading);
      qc.invalidateQueries({ queryKey: KEYS.readings });
    },
  });
}

export function useDeleteReading() {
  const qc = useQueryClient();
  const remove = useAppStore((s) => s.removeReading);
  return useMutation({
    mutationFn: async (id: string) => {
      await fetch(`/api/readings/${id}`, { method: "DELETE" });
    },
    onSuccess: (_v, id) => {
      remove(id);
      qc.invalidateQueries({ queryKey: KEYS.readings });
    },
  });
}

export function useUpdateReading() {
  const qc = useQueryClient();
  const upsert = useAppStore((s) => s.upsertReading);
  return useMutation({
    mutationFn: async (input: {
      id: string;
      value?: number;
      type?: ReadingType;
      timestamp?: number;
      notes?: string;
      carbs?: number;
      insulin?: number;
    }) => {
      const { id, ...payload } = input;
      const res = await fetch(`/api/readings/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });
      if (!res.ok) throw new Error("failed");
      const data = await res.json();
      return normalizeReading(data.reading);
    },
    onSuccess: (reading) => {
      upsert(reading);
      qc.invalidateQueries({ queryKey: KEYS.readings });
    },
  });
}

// ===== Reminders =====
export function useReminders() {
  const setReminders = useAppStore((s) => s.setReminders);
  const q = useQuery({
    queryKey: KEYS.reminders,
    queryFn: () => fetchJSON<{ reminders: Reminder[] }>("/api/reminders"),
    staleTime: 30_000,
  });

  useEffect(() => {
    if (q.data?.reminders) {
      setReminders(q.data.reminders);
    }
  }, [q.data, setReminders]);

  return q;
}

export function useAddReminder() {
  const qc = useQueryClient();
  const upsert = useAppStore((s) => s.upsertReminder);
  return useMutation({
    mutationFn: async (input: {
      time: string;
      label: string;
      type: ReadingType;
      enabled: boolean;
    }) => {
      const res = await fetch("/api/reminders", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });
      if (!res.ok) throw new Error("failed");
      const data = await res.json();
      return data.reminder as Reminder;
    },
    onSuccess: (reminder) => {
      upsert(reminder);
      qc.invalidateQueries({ queryKey: KEYS.reminders });
    },
  });
}

export function useToggleReminder() {
  const qc = useQueryClient();
  const upsert = useAppStore((s) => s.upsertReminder);
  return useMutation({
    mutationFn: async ({ id, enabled }: { id: string; enabled: boolean }) => {
      const res = await fetch(`/api/reminders/${id}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ enabled }),
      });
      if (!res.ok) throw new Error("failed");
      const data = await res.json();
      return data.reminder as Reminder;
    },
    onSuccess: (reminder) => {
      upsert(reminder);
      qc.invalidateQueries({ queryKey: KEYS.reminders });
    },
  });
}

export function useDeleteReminder() {
  const qc = useQueryClient();
  const remove = useAppStore((s) => s.removeReminder);
  return useMutation({
    mutationFn: async (id: string) => {
      await fetch(`/api/reminders/${id}`, { method: "DELETE" });
    },
    onSuccess: (_v, id) => {
      remove(id);
      qc.invalidateQueries({ queryKey: KEYS.reminders });
    },
  });
}

// ===== Settings =====
export function useSettings() {
  const setSettings = useAppStore((s) => s.setSettings);
  const setOnboarded = useAppStore((s) => s.setOnboarded);
  const q = useQuery({
    queryKey: KEYS.settings,
    queryFn: () => fetchJSON<{ settings: Settings }>("/api/settings"),
    staleTime: Infinity,
  });

  useEffect(() => {
    if (q.data?.settings) {
      setSettings(q.data.settings);
      setOnboarded(q.data.settings.onboarded);
    }
  }, [q.data, setSettings, setOnboarded]);

  return q;
}

export function useUpdateSettings() {
  const qc = useQueryClient();
  const setSettings = useAppStore((s) => s.setSettings);
  return useMutation({
    mutationFn: async (input: Partial<Settings>) => {
      const res = await fetch("/api/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });
      if (!res.ok) throw new Error("failed");
      const data = await res.json();
      return data.settings as Settings;
    },
    onSuccess: (settings) => {
      setSettings(settings);
      qc.invalidateQueries({ queryKey: KEYS.settings });
    },
  });
}

// ===== Seed =====
export function useSeed() {
  return useMutation({
    mutationFn: async () => fetchJSON<{ ok: boolean }>("/api/seed", { method: "POST" }),
  });
}

// ===== Sync status =====
export interface SyncStatus {
  id: number;
  provider: string;
  connected: boolean;
  accountEmail: string | null;
  lastSyncAt: string | null;
  lastSyncStatus: string | null;
  lastSyncError: string | null;
  driveFileId: string | null;
}

export function useSyncStatus() {
  return useQuery({
    queryKey: KEYS.syncStatus,
    queryFn: () => fetchJSON<{ state: SyncStatus }>("/api/sync/status"),
    staleTime: 10_000,
  });
}

// ===== Sync config (Google client ID etc.) =====
export interface SyncConfig {
  googleClientId: string;
  scope: string;
}

export function useSyncConfig() {
  return useQuery({
    queryKey: KEYS.syncConfig,
    queryFn: () => fetchJSON<SyncConfig>("/api/sync/config"),
    staleTime: Infinity,
  });
}

// ===== Google Drive actions =====
export function useConnectDrive() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (accessToken: string) => {
      const res = await fetch("/api/sync/google-drive", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "connect", accessToken }),
      });
      if (!res.ok) throw new Error("connect_failed");
      return res.json();
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: KEYS.syncStatus });
    },
  });
}

export function useDisconnectDrive() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      await fetch("/api/sync/google-drive", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "disconnect" }),
      });
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: KEYS.syncStatus });
    },
  });
}

export function useUploadToDrive() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const res = await fetch("/api/sync/google-drive", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "upload" }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "upload_failed");
      return data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: KEYS.syncStatus });
    },
  });
}

export function useDownloadFromDrive() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const res = await fetch("/api/sync/google-drive?action=download");
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "download_failed");
      return data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: KEYS.syncStatus });
      qc.invalidateQueries({ queryKey: KEYS.readings });
      qc.invalidateQueries({ queryKey: KEYS.reminders });
    },
  });
}

// ===== Local file export/import =====
export function downloadLocalBackup() {
  // Direct download via GET
  window.open("/api/sync/local-export", "_blank");
}

export function useImportLocalBackup() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (file: File) => {
      const text = await file.text();
      const json = JSON.parse(text);
      const res = await fetch("/api/sync/local-import", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(json),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error || "import_failed");
      return data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: KEYS.readings });
      qc.invalidateQueries({ queryKey: KEYS.reminders });
    },
  });
}
