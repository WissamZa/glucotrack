import type { Language, ReadingType, DiabetesType, ReadingStatus } from "./types";

type Dict = Record<string, string>;

const ar: Dict = {
  // App
  app_name: "سُكَّري",
  app_tagline: "تابع سكرك بصحة وثقة",

  // Onboarding
  welcome: "مرحباً بك",
  choose_language: "اختر اللغة",
  choose_style: "اختر نمط العرض",
  style_classic: "الطبي الكلاسيكي",
  style_classic_desc: "أنيق ومهني بألوان هادئة",
  style_modern: "حديث شبابي",
  style_modern_desc: "تصميم عصري بألوان نابضة",
  style_elder: "ودود لكبار السن",
  style_elder_desc: "خطوط كبيرة وتباين عالٍ",
  get_started: "ابدأ الآن",
  your_name: "اسمك",
  your_diabetes_type: "نوع السكري لديك",
  diabetes_type1: "النوع الأول",
  diabetes_type2: "النوع الثاني",
  diabetes_gestational: "سكر الحمل",

  // Nav
  nav_home: "الرئيسية",
  nav_trends: "الاتجاهات",
  nav_add: "إضافة",
  nav_chart: "الرسم",
  nav_reminders: "التذكيرات",
  nav_settings: "الإعدادات",

  // Sort
  sort_by: "ترتيب حسب",
  sort_newest: "الأحدث",
  sort_oldest: "الأقدم",
  sort_highest: "الأعلى",
  sort_lowest: "الأدنى",

  // Edit reading
  edit_reading: "تعديل القراءة",
  edited_success: "تم تحديث القراءة بنجاح",
  delete_reading: "حذف القراءة",
  delete_confirm: "هل تريد حذف هذه القراءة؟",
  deleted_success: "تم حذف القراءة",
  edit: "تعديل",
  delete: "حذف",

  // Google Sign-In
  google_signin: "تسجيل الدخول بحساب Google",
  google_signin_desc: "ارفع بياناتك إلى Google Drive الخاص بحسابك",
  google_account: "حساب Google",
  signing_in: "جارٍ تسجيل الدخول...",
  signout: "تسجيل الخروج",
  drive_connected_as: "متصل باسم",
  your_data_your_account: "كل مستخدم يرفع بياناته في حسابه الخاص",

  // Home
  good_morning: "صباح الخير",
  good_afternoon: "مساء الخير",
  good_evening: "مساء الخير",
  good_night: "طاب ليلك",
  today_summary: "ملخص اليوم",
  latest_reading: "آخر قراءة",
  avg_today: "المتوسط اليومي",
  readings_count: "عدد القراءات",
  in_range_pct: "نسبة الوقت في النطاق",
  no_readings_yet: "لا توجد قراءات بعد",
  add_first_reading: "أضف قراءتك الأولى الآن",
  recent_readings: "أحدث القراءات",
  view_all: "عرض الكل",
  today: "اليوم",
  yesterday: "أمس",
  days_ago: "منذ يومين",

  // Reading types
  type_fasting: "صائم",
  type_before_meal: "قبل الأكل",
  type_after_meal: "بعد الأكل",
  type_before_sleep: "قبل النوم",
  type_after_exercise: "بعد الرياضة",
  type_other: "أخرى",

  // Status
  status_low: "منخفض",
  status_in_range: "ضمن النطاق",
  status_high: "مرتفع",
  status_critical_low: "حرج منخفض",
  status_critical_high: "حرج مرتفع",

  // Add Reading
  add_reading: "إضافة قراءة جديدة",
  glucose_value: "قيمة السكر",
  measurement_type: "نوع القياس",
  time: "الوقت",
  notes: "ملاحظات",
  notes_placeholder: "أضف ملاحظة (اختياري)",
  carbs_grams: "الكربوهيدرات (غرام)",
  insulin_units: "الأنسولين (وحدة)",
  save: "حفظ",
  cancel: "إلغاء",
  saved_success: "تم حفظ القراءة بنجاح",
  invalid_value: "أدخل قيمة صحيحة (20-600)",
  quick_add: "إضافة سريعة",

  // Trends
  trends: "الاتجاهات",
  period_today: "اليوم",
  period_week: "الأسبوع",
  period_month: "الشهر",
  glucose_chart: "منحنى السكر",
  by_type: "حسب نوع القياس",
  statistics: "الإحصائيات",
  stat_avg: "المتوسط",
  stat_max: "الأعلى",
  stat_min: "الأدنى",
  stat_readings: "القراءات",
  stat_in_range: "في النطاق",
  no_data_period: "لا توجد بيانات في هذه الفترة",

  // Reminders
  reminders: "التذكيرات",
  add_reminder: "إضافة تذكير",
  reminder_time: "الوقت",
  reminder_label: "الوصف",
  no_reminders: "لا توجد تذكيرات بعد",
  enable_reminder: "تفعيل",
  delete_reminder: "حذف",
  reminder_added: "تم إضافة التذكير",
  reminder_deleted: "تم حذف التذكير",

  // Settings
  settings: "الإعدادات",
  general: "عام",
  language: "اللغة",
  appearance: "المظهر",
  display_style: "نمط العرض",
  health: "الصحة",
  diabetes_type: "نوع السكري",
  glucose_targets: "النطاق المستهدف",
  target_min: "الحد الأدنى",
  target_max: "الحد الأعلى",
  glucose_unit: "وحدة القياس",
  unit_mg: "ملغ/ديسيلتر",
  unit_mmol: "مليمول/لتر",
  profile: "الملف الشخصي",
  name: "الاسم",
  integrations: "التكاملات",
  device_integration: "ربط الأجهزة",
  coming_soon: "قيد التطوير",
  coming_soon_desc: "سنضيف دعم أجهزة Accu-Chek و FreeStyle Libre قريباً",
  about: "حول التطبيق",
  version: "الإصدار",
  reset_data: "إعادة تعيين البيانات",
  reset_confirm: "هل أنت متأكد من حذف جميع البيانات؟",
  reset_done: "تمت إعادة التعيين",
  save_settings: "تم حفظ الإعدادات",

  // Common
  mg_dl: "ملغ/ديسيلتر",
  yes: "نعم",
  no: "لا",
  ok: "حسناً",
  back: "رجوع",
  close: "إغلاق",
};

const en: Dict = {
  app_name: "GlucoTrack",
  app_tagline: "Track your glucose with confidence",

  welcome: "Welcome",
  choose_language: "Choose Language",
  choose_style: "Choose Display Style",
  style_classic: "Classic Medical",
  style_classic_desc: "Elegant & professional, soft colors",
  style_modern: "Modern Youth",
  style_modern_desc: "Contemporary design, vibrant colors",
  style_elder: "Elder Friendly",
  style_elder_desc: "Large fonts, high contrast",
  get_started: "Get Started",
  your_name: "Your Name",
  your_diabetes_type: "Your Diabetes Type",
  diabetes_type1: "Type 1",
  diabetes_type2: "Type 2",
  diabetes_gestational: "Gestational",

  nav_home: "Home",
  nav_trends: "Trends",
  nav_add: "Add",
  nav_chart: "Chart",
  nav_reminders: "Reminders",
  nav_settings: "Settings",

  // Sort
  sort_by: "Sort by",
  sort_newest: "Newest",
  sort_oldest: "Oldest",
  sort_highest: "Highest",
  sort_lowest: "Lowest",

  // Edit reading
  edit_reading: "Edit Reading",
  edited_success: "Reading updated successfully",
  delete_reading: "Delete Reading",
  delete_confirm: "Do you want to delete this reading?",
  deleted_success: "Reading deleted",
  edit: "Edit",
  delete: "Delete",

  // Google Sign-In
  google_signin: "Sign in with Google",
  google_signin_desc: "Back up to your own Google Drive",
  google_account: "Google Account",
  signing_in: "Signing in...",
  signout: "Sign out",
  drive_connected_as: "Connected as",
  your_data_your_account: "Each user backs up data to their own account",

  good_morning: "Good morning",
  good_afternoon: "Good afternoon",
  good_evening: "Good evening",
  good_night: "Good night",
  today_summary: "Today's Summary",
  latest_reading: "Latest Reading",
  avg_today: "Daily Average",
  readings_count: "Readings",
  in_range_pct: "Time in Range",
  no_readings_yet: "No readings yet",
  add_first_reading: "Add your first reading now",
  recent_readings: "Recent Readings",
  view_all: "View All",
  today: "Today",
  yesterday: "Yesterday",
  days_ago: "2 days ago",

  type_fasting: "Fasting",
  type_before_meal: "Before Meal",
  type_after_meal: "After Meal",
  type_before_sleep: "Before Sleep",
  type_after_exercise: "After Exercise",
  type_other: "Other",

  status_low: "Low",
  status_in_range: "In Range",
  status_high: "High",
  status_critical_low: "Critical Low",
  status_critical_high: "Critical High",

  add_reading: "Add New Reading",
  glucose_value: "Glucose Value",
  measurement_type: "Measurement Type",
  time: "Time",
  notes: "Notes",
  notes_placeholder: "Add a note (optional)",
  carbs_grams: "Carbs (g)",
  insulin_units: "Insulin (units)",
  save: "Save",
  cancel: "Cancel",
  saved_success: "Reading saved successfully",
  invalid_value: "Enter a valid value (20-600)",
  quick_add: "Quick Add",

  trends: "Trends",
  period_today: "Today",
  period_week: "Week",
  period_month: "Month",
  glucose_chart: "Glucose Curve",
  by_type: "By Measurement Type",
  statistics: "Statistics",
  stat_avg: "Average",
  stat_max: "Max",
  stat_min: "Min",
  stat_readings: "Readings",
  stat_in_range: "In Range",
  no_data_period: "No data in this period",

  reminders: "Reminders",
  add_reminder: "Add Reminder",
  reminder_time: "Time",
  reminder_label: "Label",
  no_reminders: "No reminders yet",
  enable_reminder: "Enable",
  delete_reminder: "Delete",
  reminder_added: "Reminder added",
  reminder_deleted: "Reminder deleted",

  settings: "Settings",
  general: "General",
  language: "Language",
  appearance: "Appearance",
  display_style: "Display Style",
  health: "Health",
  diabetes_type: "Diabetes Type",
  glucose_targets: "Target Range",
  target_min: "Minimum",
  target_max: "Maximum",
  glucose_unit: "Measurement Unit",
  unit_mg: "mg/dL",
  unit_mmol: "mmol/L",
  profile: "Profile",
  name: "Name",
  integrations: "Integrations",
  device_integration: "Device Integration",
  coming_soon: "Coming Soon",
  coming_soon_desc: "Accu-Chek & FreeStyle Libre support coming soon",
  about: "About",
  version: "Version",
  reset_data: "Reset Data",
  reset_confirm: "Are you sure you want to delete all data?",
  reset_done: "Reset complete",
  save_settings: "Settings saved",

  mg_dl: "mg/dL",
  yes: "Yes",
  no: "No",
  ok: "OK",
  back: "Back",
  close: "Close",
};

export const translations: Record<Language, Dict> = { ar, en };

export function t(lang: Language, key: string): string {
  return translations[lang]?.[key] ?? key;
}

export function readingTypeLabel(lang: Language, type: ReadingType): string {
  return t(lang, `type_${type}`);
}

export function statusLabel(lang: Language, status: ReadingStatus): string {
  return t(lang, `status_${status}`);
}

export function diabetesTypeLabel(lang: Language, type: DiabetesType): string {
  if (type === "type1") return t(lang, "diabetes_type1");
  if (type === "type2") return t(lang, "diabetes_type2");
  return t(lang, "diabetes_gestational");
}
