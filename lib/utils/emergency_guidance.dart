// Emergency first-aid guidance for critical glucose readings.
//
// Pure logic + content — no Flutter dependencies — so it stays unit-testable.
// Thresholds mirror Reading.status(): criticalLow < 54 mg/dL (Level 2 hypo),
// warningLow 54–69 (Level 1 hypo), criticalHigh > 250 mg/dL.
//
// This is general first-aid education, not a prescription. Every guidance
// points the patient to their care team for treatment decisions.
import '../models/reading.dart';

/// Severity of the guidance — drives the color/urgency of the UI card.
enum EmergencyLevel { low, warningLow, high }

class EmergencyGuidance {
  final EmergencyLevel level;
  final String titleAr;
  final String titleEn;
  final List<String> stepsAr;
  final List<String> stepsEn;
  final String seekHelpAr;
  final String seekHelpEn;

  const EmergencyGuidance({
    required this.level,
    required this.titleAr,
    required this.titleEn,
    required this.stepsAr,
    required this.stepsEn,
    required this.seekHelpAr,
    required this.seekHelpEn,
  });

  List<String> steps(bool arabic) => arabic ? stepsAr : stepsEn;
  String title(bool arabic) => arabic ? titleAr : titleEn;
  String seekHelp(bool arabic) => arabic ? seekHelpAr : seekHelpEn;
}

class EmergencyGuide {
  EmergencyGuide._();

  /// Returns guidance for a glucose value, or `null` when the value is not
  /// in a critical/warning band.
  static EmergencyGuidance? forValue(int valueMgDl) {
    if (valueMgDl < 54) return _criticalLow;
    if (valueMgDl < 70) return _warningLow;
    if (valueMgDl > 250) return _criticalHigh;
    return null;
  }

  static EmergencyGuidance? forStatus(ReadingStatus status, int valueMgDl) {
    switch (status) {
      case ReadingStatus.criticalLow:
      case ReadingStatus.warningLow:
      case ReadingStatus.criticalHigh:
        return forValue(valueMgDl);
      case ReadingStatus.low:
      case ReadingStatus.inRange:
      case ReadingStatus.high:
        return null;
    }
  }

  /// Severe hypoglycemia (< 54 mg/dL) — Level 2 hypo, act immediately.
  static const _criticalLow = EmergencyGuidance(
    level: EmergencyLevel.low,
    titleAr: 'هبوط حاد في السكر — تصرّف الآن',
    titleEn: 'Severe Low Blood Sugar — Act Now',
    stepsAr: [
      'توقف عن أي نشاط واجلس أو استلقِ — لا تقُد سيارة ولا تشغّل آلات خطرة.',
      'تناول 15–20 غراماً سكراً سريعاً فوراً: نصف كوب عصير، 3 تمرات، ملعقة كبيرة عسل، أو أقراص جلوكوز.',
      'أعد القياس بعد 15 دقيقة؛ إن بقيت أقل من 70 أعد العلاج نفسه.',
      'عند تجاوز 70 وتأخر وجبتك أكثر من ساعة، تناول وجبة خفيفة تحتوي نشويات.',
      'أخبر شخصاً قريباً بما يحدث وابقَ برفقة حتى تستقر.',
    ],
    stepsEn: [
      'Stop any activity and sit or lie down — do not drive or operate machinery.',
      'Take 15–20 g of fast sugar right away: half a cup of juice, 3 dates, a tablespoon of honey, or glucose tablets.',
      'Recheck after 15 minutes; if still below 70, repeat the same treatment.',
      'Once above 70 and your next meal is more than an hour away, eat a snack containing carbs.',
      'Tell someone nearby what is happening and stay with them until you are stable.',
    ],
    seekHelpAr: 'اطلب إسعافاً فوراً (أو استخدم الجلوكاجون) في حال: فقدان الوعي، عدم القدرة على البلع، عدم الاستجابة للعلاج بعد تكرارين، أو قراءة أقل من 54 بعد العلاج.',
    seekHelpEn: 'Call emergency services (or use glucagon) immediately if: there is loss of consciousness, swallowing is not possible, the reading stays below 54 after two treatment rounds, or symptoms do not improve.',
  );

  /// Mild hypoglycemia (54–69 mg/dL) — Level 1 hypo, treat with 15-15 rule.
  static const _warningLow = EmergencyGuidance(
    level: EmergencyLevel.warningLow,
    titleAr: 'سكر منخفض — قاعدة 15-15',
    titleEn: 'Low Blood Sugar — the 15-15 Rule',
    stepsAr: [
      'تناول 15 غراماً سكراً سريعاً: نصف كوب عصير، 3 تمرات، أو أقراص جلوكوز.',
      'انتظر 15 دقيقة ثم أعد القياس.',
      'كرر الخطوة إن بقيت القراءة أقل من 70.',
      'تناول وجبة أو سناك نشويات عند اقتراب الوجبة التالية بأكثر من ساعة.',
    ],
    stepsEn: [
      'Take 15 g of fast sugar: half a cup of juice, 3 dates, or glucose tablets.',
      'Wait 15 minutes, then recheck.',
      'Repeat if the reading is still below 70.',
      'Eat a meal or carb-containing snack if your next meal is more than an hour away.',
    ],
    seekHelpAr: 'راجع طبيبك إذا تكرر الهبوط خلال اليوم الواحد أو دون سبب واضح — قد تحتاج تعديل خطة العلاج.',
    seekHelpEn: 'Contact your doctor if lows recur within the same day or without an obvious cause — your treatment plan may need adjusting.',
  );

  /// Severe hyperglycemia (> 250 mg/dL).
  static const _criticalHigh = EmergencyGuidance(
    level: EmergencyLevel.high,
    titleAr: 'ارتفاع حاد في السكر',
    titleEn: 'Severe High Blood Sugar',
    stepsAr: [
      'اشرب ماءً بكثرة (بدون سكر) للمساعدة في التخلص من السكر الزائد.',
      'تجنب التمارين الشاقة حتى تنخفض القراءة وتستبعد الكيتون.',
      'أعد القياس بعد ساعتين وسجّل القراءة مع ما أكلته أو شعرت به.',
      'افحص الكيتون إن توفرت شرائط وعندك سكر >250 مع غثيان أو ألم بطن أو تعب.',
      'خذ أدويتك كالمعتاد — لا تضاعف جرعة الأنسولين من تلقاء نفسك.',
    ],
    stepsEn: [
      'Drink plenty of water (sugar-free) to help flush out excess glucose.',
      'Avoid strenuous exercise until the reading drops and ketones are ruled out.',
      'Recheck in two hours and log the reading with what you ate or felt.',
      'Test ketones if you have strips and your sugar is >250 with nausea, stomach pain, or fatigue.',
      'Take your medication as usual — never double your insulin dose on your own.',
    ],
    seekHelpAr: 'اتصل بطبيبك فوراً عند: وجود كيتون في البول، استمرار القراءة فوق 300، قيء متكرر، أو أعراض الحماض الكيتوني (تنفس سريع، رائحة أسيتون، تشوش).',
    seekHelpEn: 'Call your doctor immediately if: ketones are present, the reading stays above 300, vomiting persists, or ketoacidosis symptoms appear (rapid breathing, acetone breath, confusion).',
  );
}
