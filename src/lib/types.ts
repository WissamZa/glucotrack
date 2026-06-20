// أنواع البيانات الأساسية للتطبيق

export type ReadingType =
  | "fasting"
  | "before_meal"
  | "after_meal"
  | "before_sleep"
  | "after_exercise"
  | "other";

export type DiabetesType = "type1" | "type2" | "gestational";

export type Language = "ar" | "en";

export type ThemeStyle = "classic" | "modern" | "elder";

export type GlucoseUnit = "mg_dL" | "mmol_L";

export type ScreenName =
  | "onboarding"
  | "home"
  | "add"
  | "trends"
  | "reminders"
  | "settings";

export interface Reading {
  id: string;
  value: number; // mg/dL
  type: ReadingType;
  timestamp: number;
  notes?: string;
  carbs?: number;
  insulin?: number;
}

export interface Reminder {
  id: string;
  time: string; // "08:00"
  label: string;
  enabled: boolean;
  type: ReadingType;
}

export interface Settings {
  language: Language;
  theme: ThemeStyle;
  diabetesType: DiabetesType;
  targetMin: number; // mg/dL
  targetMax: number; // mg/dL
  unit: GlucoseUnit;
  userName: string;
}

// تصنيف القراءة حسب النطاق المستهدف
export type ReadingStatus = "low" | "in_range" | "high" | "critical_low" | "critical_high";

export function getStatus(value: number, min: number, max: number): ReadingStatus {
  if (value < 54) return "critical_low";
  if (value < min) return "low";
  if (value <= max) return "in_range";
  if (value <= 250) return "high";
  return "critical_high";
}
