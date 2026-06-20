import type { Reading, Reminder, Settings } from "./types";

// إعدادات افتراضية
export const defaultSettings: Settings = {
  language: "ar",
  theme: "classic",
  diabetesType: "type2",
  targetMin: 80,
  targetMax: 180,
  unit: "mg_dL",
  userName: "",
};

// توليد قراءات تجريبية لآخر 7 أيام
function generateSeedReadings(): Reading[] {
  const readings: Reading[] = [];
  const now = Date.now();
  const dayMs = 24 * 60 * 60 * 1000;

  // أنماط واقعية: صباحي مرتفع قليلاً، بعد الأكل مرتفع، قبل النوم معتدل
  const patterns: Array<{
    type: Reading["type"];
    hour: number;
    baseValue: number;
    variance: number;
  }> = [
    { type: "fasting", hour: 7, baseValue: 110, variance: 25 },
    { type: "after_meal", hour: 9, baseValue: 165, variance: 30 },
    { type: "before_meal", hour: 13, baseValue: 105, variance: 20 },
    { type: "after_meal", hour: 15, baseValue: 175, variance: 35 },
    { type: "before_sleep", hour: 22, baseValue: 130, variance: 25 },
  ];

  for (let d = 6; d >= 0; d--) {
    for (const p of patterns) {
      // تخطي بعض القراءات بشكل عشوائي ليكون واقعياً
      if (Math.random() < 0.15 && d < 6) continue;
      const value = Math.round(p.baseValue + (Math.random() - 0.5) * 2 * p.variance);
      const ts = now - d * dayMs;
      const date = new Date(ts);
      date.setHours(p.hour, Math.floor(Math.random() * 50), 0, 0);
      readings.push({
        id: `seed-${d}-${p.type}-${p.hour}`,
        value: Math.max(60, Math.min(280, value)),
        type: p.type,
        timestamp: date.getTime(),
        notes: d === 0 && p.type === "after_meal" ? "بعد وجبة الغداء" : undefined,
      });
    }
  }

  // قراءة اليوم الأحدث
  const today = new Date();
  today.setHours(today.getHours() - 1, 30, 0, 0);
  readings.push({
    id: "seed-today-latest",
    value: 142,
    type: "after_meal",
    timestamp: today.getTime(),
    notes: "بعد وجبة خفيفة",
  });

  return readings.sort((a, b) => b.timestamp - a.timestamp);
}

export const seedReadings: Reading[] = generateSeedReadings();

export const seedReminders: Reminder[] = [
  {
    id: "rem-1",
    time: "07:00",
    label: "قياس الصائم",
    enabled: true,
    type: "fasting",
  },
  {
    id: "rem-2",
    time: "14:00",
    label: "بعد الغداء",
    enabled: true,
    type: "after_meal",
  },
  {
    id: "rem-3",
    time: "22:00",
    label: "قبل النوم",
    enabled: false,
    type: "before_sleep",
  },
];
