// Bilingual patient-education content for GlucoTrack.
//
// Tips ship with the app (not the database) so they work fully offline,
// never change under the user's feet, and update with app releases.
// Content is general diabetes self-care education sourced from widely
// accepted guidance (ADA-style advice) — it is not a substitute for
// professional medical advice; the tips screen shows a disclaimer.
import 'package:flutter/material.dart';

import '../models/settings.dart';

enum TipCategoryId {
  nutrition,
  exercise,
  hypoglycemia,
  hyperglycemia,
  footCare,
  medication,
  monitoring,
  mentalHealth,
  ramadan,
}

class TipCategoryMeta {
  final TipCategoryId id;
  final String labelAr;
  final String labelEn;
  final IconData icon;

  const TipCategoryMeta(this.id, this.labelAr, this.labelEn, this.icon);

  String label(Language lang) => lang == Language.ar ? labelAr : labelEn;
}

const kTipCategories = <TipCategoryMeta>[
  TipCategoryMeta(
    TipCategoryId.nutrition,
    'التغذية',
    'Nutrition',
    Icons.restaurant_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.exercise,
    'النشاط البدني',
    'Exercise',
    Icons.directions_walk_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.hypoglycemia,
    'هبوط السكر',
    'Low Sugar',
    Icons.south_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.hyperglycemia,
    'ارتفاع السكر',
    'High Sugar',
    Icons.north_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.footCare,
    'العناية بالقدمين',
    'Foot Care',
    Icons.do_not_step_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.medication,
    'الدواء والأنسولين',
    'Medication & Insulin',
    Icons.medication_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.monitoring,
    'المراقبة والقياس',
    'Monitoring',
    Icons.monitor_heart_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.mentalHealth,
    'الصحة النفسية',
    'Mental Wellbeing',
    Icons.self_improvement_outlined,
  ),
  TipCategoryMeta(
    TipCategoryId.ramadan,
    'صيام رمضان',
    'Ramadan Fasting',
    Icons.nightlight_outlined,
  ),
];

class HealthTip {
  final String id;
  final TipCategoryId category;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;

  const HealthTip({
    required this.id,
    required this.category,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
  });

  String title(Language lang) => lang == Language.ar ? titleAr : titleEn;
  String body(Language lang) => lang == Language.ar ? bodyAr : bodyEn;
}

const kHealthTips = <HealthTip>[
  // ── التغذية / Nutrition ───────────────────────────────────────────────
  HealthTip(
    id: 'plate_method',
    category: TipCategoryId.nutrition,
    titleAr: 'طريقة الطبق المتوازن',
    titleEn: 'The balanced plate method',
    bodyAr: 'قسّم طبقك بصرياً: نصف خضار غير نشوية، ربع بروتين (دجاج، سمك، بقوليات)، وربع نشويات معقدة (أرز بني، برغل). بلا حسابات معقدة تحصل على وجبة متوازنة تساعد على ثبات السكر.',
    bodyEn: 'Divide your plate visually: half non-starchy vegetables, a quarter protein (chicken, fish, legumes), and a quarter complex carbs (brown rice, bulgur). You get a balanced, glucose-friendly meal without complex counting.',
  ),
  HealthTip(
    id: 'carb_counting',
    category: TipCategoryId.nutrition,
    titleAr: 'تعلّم عدّ الكربوهيدرات',
    titleEn: 'Learn to count carbs',
    bodyAr: 'الكربوهيدرات هي أكثر مكوّن يؤثر في قراءة السكر بعد الأكل. تعلّم تقديرها في وجباتك المعتادة (الخبز، الأرز، الفواكه، الحليب) وسجّلها في ملاحظات القراءة — ستكتشف أنماطك بسرعة.',
    bodyEn: 'Carbs are the biggest driver of post-meal readings. Learn to estimate them in your usual meals (bread, rice, fruit, milk) and log them in the reading notes — you will spot your patterns quickly.',
  ),
  HealthTip(
    id: 'glycemic_index',
    category: TipCategoryId.nutrition,
    titleAr: 'اختر النشويات بطيئة الامتصاص',
    titleEn: 'Choose slow-absorbing carbs',
    bodyAr: 'الحبوب الكاملة والبقوليات والشوفان ترفع السكر ببطء مقارنة بالخبز الأبيض والأرز الأبيض والبطاطس. استبدال واحد بسيط في الوجبة يمكن أن ينعكس على قمم السكر بعد الأكل.',
    bodyEn: 'Whole grains, legumes, and oats raise glucose slowly compared to white bread, white rice, and potatoes. One simple swap per meal can noticeably flatten your post-meal peaks.',
  ),
  HealthTip(
    id: 'fiber',
    category: TipCategoryId.nutrition,
    titleAr: 'الألياف صديقة السكر',
    titleEn: 'Fiber is glucose\'s friend',
    bodyAr: 'استهدف 25–30 غراماً من الألياف يومياً من الخضار والبقول والحبوب الكاملة؛ فهي تبطئ امتصاص السكر وتزيد الشبع وتدعم الكوليسترول. ابدأ تدريجياً مع شرب ماء كافٍ.',
    bodyEn: 'Aim for 25–30 g of daily fiber from vegetables, legumes, and whole grains; it slows glucose absorption, boosts satiety, and supports cholesterol. Increase gradually with plenty of water.',
  ),
  HealthTip(
    id: 'sugary_drinks',
    category: TipCategoryId.nutrition,
    titleAr: 'احذر المشروبات المحلاة',
    titleEn: 'Beware sugary drinks',
    bodyAr: 'العصائر حتى الطازجة والمشروبات الغازية ترفع السكر بسرعة كبيرة لأنها بلا ألياف. الماء والماء بالنعناع والشاي والقهوة بدون سكر خيارات أفضل للاعتداء اليومي.',
    bodyEn: 'Juices — even fresh — and sodas spike glucose very fast because they carry no fiber. Water, mint water, and unsweetened tea or coffee are better everyday choices.',
  ),
  HealthTip(
    id: 'regular_meals',
    category: TipCategoryId.nutrition,
    titleAr: 'التزم بمواعيد الوجبات',
    titleEn: 'Keep regular meal times',
    bodyAr: 'الوجبات المنتظمة بكميات متشابهة تمنحك قراءات أكثر ثباتاً وتجعل تأثير الأدوية قابلاً للتوقع. التباس الوجبات الكبير يعقّب ضبط السكر ويشجع الإفراط لاحقاً.',
    bodyEn: 'Regular meals of similar size give steadier readings and make medication effects predictable. Large meal skipping complicates glucose control and invites overeating later.',
  ),
  // ── النشاط البدني / Exercise ──────────────────────────────────────────
  HealthTip(
    id: 'walk_after_meals',
    category: TipCategoryId.exercise,
    titleAr: 'امشِ بعد الوجبات',
    titleEn: 'Walk after meals',
    bodyAr: 'مشي 10–15 دقيقة بعد الأكل — حتى داخل المنزل — يقلل قمم السكر بعد الوجبة بوضوح. اجعلها عادة أسرية بعد الغداء والعشاء.',
    bodyEn: 'A 10–15 minute walk after eating — even indoors — clearly lowers post-meal peaks. Make it a family habit after lunch and dinner.',
  ),
  HealthTip(
    id: 'exercise_30min',
    category: TipCategoryId.exercise,
    titleAr: '30 دقيقة حركة يومياً',
    titleEn: '30 minutes of daily movement',
    bodyAr: 'استهدف 150 دقيقة أسبوعياً من النشاط المعتدل (مشي سريع، سباحة، دراجة) موزعة على أيام الأسبوع. النشاط يحسّن حساسية الأنسولين لمدة تصل إلى 48 ساعة.',
    bodyEn: 'Aim for 150 weekly minutes of moderate activity (brisk walking, swimming, cycling) spread across the week. Activity improves insulin sensitivity for up to 48 hours.',
  ),
  HealthTip(
    id: 'check_before_after',
    category: TipCategoryId.exercise,
    titleAr: 'قِس قبل التمرين وبعده',
    titleEn: 'Check before and after exercise',
    bodyAr: 'التمرين قد يخفض السكر لساعات بعده. قِس قبل البدء (يفضل ألا تكون أقل من 100) وبعد الانتهاء لتفهم استجابة جسمك وتتجنب الهبوط.',
    bodyEn: 'Exercise can lower glucose for hours afterwards. Check before starting (ideally not below 100) and afterwards to learn your body\'s response and avoid lows.',
  ),
  HealthTip(
    id: 'fast_sugar_sports',
    category: TipCategoryId.exercise,
    titleAr: 'احمل سكراً سريعاً عند الرياضة',
    titleEn: 'Carry fast sugar when exercising',
    bodyAr: 'إذا كنت تستخدم أنسولين أو أدوية سلفونيل يوريا، احمل معك تمرات أو عصيراً صغيراً أو أقراص جلوكوز عند أي تمرين — الهبوط قد يحدث بسرعة ودون إنذار.',
    bodyEn: 'If you use insulin or sulfonylureas, carry dates, a small juice, or glucose tablets for any workout — lows can come fast and without warning.',
  ),
  HealthTip(
    id: 'strength_training',
    category: TipCategoryId.exercise,
    titleAr: 'لا تهمل تمارين المقاومة',
    titleEn: 'Don\'t skip strength training',
    bodyAr: 'تمرينان إلى ثلاثة أسبوعياً بالأثقال أو أحزمة المقاومة يبنيان عضلاً يستهلك السكر ويحسّن حساسية الأنسولين — مكمل للمشي وليس بديلاً عنه.',
    bodyEn: 'Two to three weekly sessions with weights or resistance bands build muscle that consumes glucose and improves insulin sensitivity — a complement to walking, not a replacement.',
  ),
  HealthTip(
    id: 'avoid_exercise_extremes',
    category: TipCategoryId.exercise,
    titleAr: 'متى تتجنب التمرين؟',
    titleEn: 'When to skip a workout',
    bodyAr: 'تجنب التمرين الشاق إذا كان سكرك أقل من 70 (عالج الهبوط أولاً) أو أعلى من 250 مع أعراض كيتون. استأنف بعد استقرار القراءة.',
    bodyEn: 'Avoid hard exercise if your glucose is below 70 (treat the low first) or above 250 with ketone symptoms. Resume once your reading stabilizes.',
  ),
  // ── هبوط السكر / Hypoglycemia ─────────────────────────────────────────
  HealthTip(
    id: 'hypo_symptoms',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'اعرِف أعراض الهبوط',
    titleEn: 'Know the low-sugar symptoms',
    bodyAr: 'رعشة، تعرق، جوع مفاجئ، دوخة، خفقان، تشتت في التركيز أو تبيّن الكلام — قد تعني هبوطاً دون 70. لا تنتظر: قِس وعالج فوراً.',
    bodyEn: 'Shakiness, sweating, sudden hunger, dizziness, palpitations, trouble concentrating, or slurred speech — may mean a drop below 70. Don\'t wait: check and treat immediately.',
  ),
  HealthTip(
    id: 'rule_15_15',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'قاعدة 15-15 للهبوط',
    titleEn: 'The 15-15 rule for lows',
    bodyAr: 'عند قراءة أقل من 70: تناول 15 غراماً سكراً سريعاً (نصف كوب عصير، 3 تمرات، أقراص جلوكوز)، انتظر 15 دقيقة، أعد القياس، وكرر إن لزم حتى تتجاوز 70.',
    bodyEn: 'For a reading below 70: take 15 g of fast sugar (half a cup of juice, 3 dates, or glucose tablets), wait 15 minutes, recheck, and repeat until you are above 70.',
  ),
  HealthTip(
    id: 'dont_delay_treatment',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'لا تؤجل علاج الهبوط',
    titleEn: 'Never delay treating a low',
    bodyAr: 'الهبوط يتدهور خلال دقائق. عالج فوراً حتى لو كنت في اجتماع أو مسافة — أوقف السيارة أولاً دائماً قبل أي علاج أثناء القيادة.',
    bodyEn: 'Lows worsen within minutes. Treat immediately, even mid-meeting or mid-drive — always pull over first when treating while driving.',
  ),
  HealthTip(
    id: 'post_low_snack',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'بعد علاج الهبوط',
    titleEn: 'After treating a low',
    bodyAr: 'إن كانت وجبتك التالية بعد أكثر من ساعة، تناول سناكاً يحتوي نشويات معقدة (شريحة خبز بحبوب كاملة، بسكويت شوفان) لمنع عودة الهبوط.',
    bodyEn: 'If your next meal is over an hour away, eat a complex-carb snack (a slice of whole-grain bread, oat crackers) to keep the low from returning.',
  ),
  HealthTip(
    id: 'tell_people',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'أخبر من حولك',
    titleEn: 'Tell the people around you',
    bodyAr: 'العائلة والزملاء والأصدقاء يجب أن يعرفوا أعراض الهبوط وكيفية مساعدتك: عصير أو سكر، وليس طعاماً صلباً إذا كانت الوعية ضعيفة.',
    bodyEn: 'Family, colleagues, and friends should know your low symptoms and how to help: juice or sugar — not solid food if consciousness is impaired.',
  ),
  HealthTip(
    id: 'night_hypo',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'الهبوط الليلي الصامت',
    titleEn: 'Silent nighttime lows',
    bodyAr: 'التصبح متعرقاً أو بصداع أو نوم مضطرب قد يدل على هبوط ليلي. جرّب قراءة عند الاستيقاظ، وناقش مع طبيبك قراءة قبل النوم ووجبة خفيفة مناسبة.',
    bodyEn: 'Waking up sweaty, headachy, or with restless sleep may signal nighttime lows. Try a morning reading, and discuss a bedtime check and suitable snack with your doctor.',
  ),
  HealthTip(
    id: 'glucagon',
    category: TipCategoryId.hypoglycemia,
    titleAr: 'جهاز الجلوكاجون الطارئ',
    titleEn: 'Emergency glucagon',
    bodyAr: 'إن كنت معرضاً لهبوط حاد (خصوصاً مع أنسولين)، اسأل طبيبك عن وصف جلوكاجون وعلّم أفراد أسرتك أين يُحفظ وكيف يُستخدم قبل وصول الإسعاف.',
    bodyEn: 'If you are prone to severe lows (especially on insulin), ask your doctor to prescribe glucagon, and teach your family where it is kept and how to use it before the ambulance arrives.',
  ),
  // ── ارتفاع السكر / Hyperglycemia ──────────────────────────────────────
  HealthTip(
    id: 'hyper_symptoms',
    category: TipCategoryId.hyperglycemia,
    titleAr: 'اعرِف أعراض الارتفاع',
    titleEn: 'Know the high-sugar symptoms',
    bodyAr: 'عطش شديد، كثرة تبول، تعب غير معتاد، تشوش رؤية، جفاف فم — قد تعني ارتفاعاً مسبب السكر. قِس ولا تتجاهل الأعراض الممتدة ليومين أو أكثر.',
    bodyEn: 'Intense thirst, frequent urination, unusual fatigue, blurry vision, dry mouth — may mean a glucose spike. Check, and don\'t ignore symptoms lasting two days or more.',
  ),
  HealthTip(
    id: 'hydration',
    category: TipCategoryId.hyperglycemia,
    titleAr: 'الترطيب عند الارتفاع',
    titleEn: 'Hydrate during highs',
    bodyAr: 'اشرب ماءً بكثرة (بدون سكر) عند ارتفاع القراءة؛ الترطيب يساعد الكلى على التخلص من السكر الزائد ويقي من الجفاف الذي يزيد الارتفاع سوءاً.',
    bodyEn: 'Drink plenty of water (sugar-free) when readings run high; hydration helps the kidneys clear excess glucose and protects against the dehydration that worsens highs.',
  ),
  HealthTip(
    id: 'ketones',
    category: TipCategoryId.hyperglycemia,
    titleAr: 'افحص الكيتون عند الارتفاع الشديد',
    titleEn: 'Check ketones when very high',
    bodyAr: 'عند قراءة أعلى من 250 مع غثيان أو ألم بطن أو تعب، افحص الكيتون إن توفرت الشرائط. وجود كيتون يستدعي التواصل مع الطبيب في اليوم نفسه.',
    bodyEn: 'For readings above 250 with nausea, stomach pain, or fatigue, test ketones if you have strips. Ketones mean you should contact your doctor the same day.',
  ),
  HealthTip(
    id: 'hyper_causes',
    category: TipCategoryId.hyperglycemia,
    titleAr: 'ابحث عن سبب الارتفاع',
    titleEn: 'Look for the cause of highs',
    bodyAr: 'وجبة غنية بالكربوهيدرات، مرض أو التهاب، توتر، قلة نوم، نسيان دواء — كلها أسباب شائعة. سجّل الملاحظات مع القراءة لاكتشاف نمطك الخاص.',
    bodyEn: 'A carb-heavy meal, illness or infection, stress, poor sleep, a missed dose — all common causes. Log notes with readings to discover your own pattern.',
  ),
  HealthTip(
    id: 'no_self_dosing',
    category: TipCategoryId.hyperglycemia,
    titleAr: 'لا تضاعف الجرعة بنفسك',
    titleEn: 'Never double up on your own',
    bodyAr: 'لا تزيد جرعة الأنسولين لتصحيح ارتفاع دون خطة متفق عليها مع طبيبك؛ التصحيح العشوائي سبب شائع لهبوطات خطيرة.',
    bodyEn: 'Don\'t increase insulin to correct a high without a plan agreed with your doctor; improvised corrections are a common cause of severe lows.',
  ),
  // ── العناية بالقدمين / Foot care ──────────────────────────────────────
  HealthTip(
    id: 'daily_foot_check',
    category: TipCategoryId.footCare,
    titleAr: 'افحص قدميك يومياً',
    titleEn: 'Check your feet daily',
    bodyAr: 'دقيقة واحدة كل مساء: جروح، تشققات، احمرار، تورم، تغير لون. استخدم مرآة أرضية أو اطلب من أحد النظر عنك إن كان الوصول صعباً.',
    bodyEn: 'One minute every evening: cuts, cracks, redness, swelling, color change. Use a floor mirror or ask someone to look for you if reaching is hard.',
  ),
  HealthTip(
    id: 'wash_dry',
    category: TipCategoryId.footCare,
    titleAr: 'اغسل وجفف بين الأصابع',
    titleEn: 'Wash and dry between toes',
    bodyAr: 'ماء فاتر (لا ساخن — جرّبه بمرفقك) وتجفيف جيد بين الأصابع يمنع الفطريات، مع مرطب للأطراف دون ما بين الأصابع.',
    bodyEn: 'Lukewarm water (test with your elbow, not hot) and thorough drying between toes prevent fungal infections; moisturize the tops and soles but not between the toes.',
  ),
  HealthTip(
    id: 'no_barefoot',
    category: TipCategoryId.footCare,
    titleAr: 'لا تمشِ حافياً أبداً',
    titleEn: 'Never walk barefoot',
    bodyAr: 'حتى داخل المنزل: خرج زجاج أو سمكة ألماس قد لا تشعر بها مع اعتلال الأعصاب وتتحول لقرحة. حذاء أو شبشب داخلي دائماً.',
    bodyEn: 'Even indoors: a pin or glass shard you cannot feel with neuropathy can become an ulcer. Slippers or shoes at all times.',
  ),
  HealthTip(
    id: 'nail_care',
    category: TipCategoryId.footCare,
    titleAr: 'قص الأظافر بشكل صحيح',
    titleEn: 'Trim nails correctly',
    bodyAr: 'قص الأظافر مستقيماً وليس بحواف دائرية لمنع نمو الشعر داخل الجلد. إن كان القص صعباً أو لديك مشاكل بالقدمين فاستعن بمختص العناية بالأقدام.',
    bodyEn: 'Cut nails straight across rather than curved to prevent ingrown nails. If trimming is hard or you have foot problems, see a podiatrist.',
  ),
  HealthTip(
    id: 'shoes_check',
    category: TipCategoryId.footCare,
    titleAr: 'تفقد حذاءك قبل ارتدائه',
    titleEn: 'Inspect shoes before wearing',
    bodyAr: 'هزّ الحذاء وتفقّد داخله من الأحجار والحواف الصلبة. المقاس المريح بالجوارب المناسبة يقي من الاحتكاك والجروح الصامتة.',
    bodyEn: 'Shake out and feel inside shoes for stones and hard seams. Comfortable sizing with proper socks prevents friction and silent wounds.',
  ),
  HealthTip(
    id: 'annual_foot_exam',
    category: TipCategoryId.footCare,
    titleAr: 'فحص أقدام سنوي شامل',
    titleEn: 'Get an annual foot exam',
    bodyAr: 'اطلب من طبيبك فحص الإحساس (بخيط النايلون)، النبض، ومراجعة الأظافر والجلد مرة سنوياً على الأقل — أو أكثر إن كان لديك اعتلال أعصاب أو مشاكل سابقة.',
    bodyEn: 'Ask your doctor for a sensory check (monofilament), pulse assessment, and skin/nail review at least yearly — more often with neuropathy or past issues.',
  ),
  // ── الدواء والأنسولين / Medication ────────────────────────────────────
  HealthTip(
    id: 'med_adherence',
    category: TipCategoryId.medication,
    titleAr: 'الالتزام بالمواقيت',
    titleEn: 'Stay on schedule',
    bodyAr: 'خذ أدويتك في نفس الوقت يومياً — استخدم تذكيرات هذا التطبيق. الانتظام يجعل التأثير قابلاً للتوقع ويمنع نسيان الجرعات.',
    bodyEn: 'Take your medication at the same time daily — use this app\'s reminders. Consistency makes effects predictable and prevents missed doses.',
  ),
  HealthTip(
    id: 'insulin_storage',
    category: TipCategoryId.medication,
    titleAr: 'تخزين الأنسولين',
    titleEn: 'Store insulin properly',
    bodyAr: 'الأنسولين غير المستخدم في الثلاجة (2–8°م)؛ القلم المستخدم يبقى في درجة حرارة الغرفة بعيداً عن الشمس والحرارة والمركبات الحارة لمدة لا تتجاوز توصية الدواء (عادة أسابيع قليلة).',
    bodyEn: 'Unopened insulin belongs in the fridge (2–8°C); an in-use pen stays at room temperature away from sun, heat, and hot cars, within the label\'s time limit (usually a few weeks).',
  ),
  HealthTip(
    id: 'dont_stop_meds',
    category: TipCategoryId.medication,
    titleAr: 'لا تتوقف عن الدواء عند التحسن',
    titleEn: 'Don\'t stop when you feel better',
    bodyAr: 'السكري صامت — شعورك بالتحسن نتيجة الدواء لا دليل شفاء. أي تعديل أو إيقاف قرار طبي حصراً.',
    bodyEn: 'Diabetes is silent — feeling better is the medication working, not a cure. Any change or stop is strictly a doctor\'s decision.',
  ),
  HealthTip(
    id: 'expiry',
    category: TipCategoryId.medication,
    titleAr: 'راقب تاريخ الانتهاء',
    titleEn: 'Watch expiry dates',
    bodyAr: 'الشرائط والأقلام منتهية الصلاحية تعطي قراءات خاطئة وجرعات غير مضمونة. راجع تواريخ مخزونك شهرياً وتخلص من البوالص المتضررة.',
    bodyEn: 'Expired strips and pens give wrong readings and unreliable doses. Review your stock monthly and discard damaged vials.',
  ),
  HealthTip(
    id: 'sick_day_plan',
    category: TipCategoryId.medication,
    titleAr: 'خطة أيام المرض',
    titleEn: 'Have a sick-day plan',
    bodyAr: 'أثناء المرض يرتفع السكر عادة. اتفق مع طبيبك مسبقاً: هل أعدل الجرعات؟ كيف أرطب نفسي؟ متى أراجع؟ وزد وتيرة القياس أثناء المرض.',
    bodyEn: 'Glucose usually runs high during illness. Agree with your doctor in advance: do doses change? How to hydrate? When to check in? And test more often while sick.',
  ),
  HealthTip(
    id: 'rotate_sites',
    category: TipCategoryId.medication,
    titleAr: 'نوّع مواقع الحقن',
    titleEn: 'Rotate injection sites',
    bodyAr: 'بدّل نقاط الحقن داخل المنطقة نفسها (تفادي نطاق 1 سم من المرة السابقة) لتجنب سماكة الدهون التي تمتص الأنسولين بغير انتظام.',
    bodyEn: 'Rotate injection points within a zone (avoid the exact previous spot by 1 cm) to prevent fatty lumps that absorb insulin unpredictably.',
  ),
  // ── المراقبة والقياس / Monitoring ─────────────────────────────────────
  HealthTip(
    id: 'vary_times',
    category: TipCategoryId.monitoring,
    titleAr: 'وزّع أوقات القياس',
    titleEn: 'Vary your checking times',
    bodyAr: 'قِس في أوقات مختلفة عبر الأسبوع (صائم، قبل وبعد وجبات، قبل النوم) لرؤية الصورة الكاملة — كل وقت يروي جزءاً من القصة.',
    bodyEn: 'Check at different times across the week (fasting, before/after meals, bedtime) to see the full picture — each slot tells part of the story.',
  ),
  HealthTip(
    id: 'pre_appointment',
    category: TipCategoryId.monitoring,
    titleAr: 'استعد لمواعيد طبيبك',
    titleEn: 'Prepare for doctor visits',
    bodyAr: 'قبل الموعد راجع قسم "تحليلات" في التطبيق: متوسطك، وقتك في النطاق، واتجاهك. صدّر تقرير PDF وخذه — يعطي طبيبك صورة أدق من الذاكرة.',
    bodyEn: 'Before an appointment review the app\'s "Insights": your average, time in range, and trend. Export the PDF report and bring it — it gives your doctor a far clearer picture than memory.',
  ),
  HealthTip(
    id: 'strip_care',
    category: TipCategoryId.monitoring,
    titleAr: 'اهتم بشرائط القياس',
    titleEn: 'Care for test strips',
    bodyAr: 'خزن الشرائط في علبتها بعيداً عن الحرارة والرطوبة والحمّام، وأغلق الوعاء فوراً بعد أخذ شريط. أعد معايرة الجهاز عند تبديل عبوات الشرائط إن كان يدعم ذلك.',
    bodyEn: 'Store strips in their vial away from heat, humidity, and bathrooms, and close the vial right after taking one. Recalibrate your meter when switching strip lots if it supports it.',
  ),
  HealthTip(
    id: 'wash_hands',
    category: TipCategoryId.monitoring,
    titleAr: 'اغسل يديك قبل الوخز',
    titleEn: 'Wash hands before testing',
    bodyAr: 'بقايا فواكه أو طعام على الأصابع ترفع القراءة زوراً بشكل كبير. ماء وصابون أو منديل كحولي — وجفف قبل الوخز.',
    bodyEn: 'Food or fruit residue on fingers can falsely inflate readings a lot. Soap and water or an alcohol wipe — then dry before testing.',
  ),
  HealthTip(
    id: 'one_reading_is_not_a_verdict',
    category: TipCategoryId.monitoring,
    titleAr: 'قراءة واحدة ليست حكماً',
    titleEn: 'One reading is not a verdict',
    bodyAr: 'القيمة الواحدة لمحة لحظية تتأثر بكل شيء. الانضباط الحقيقي يظهر في المتوسط والاتجاه عبر أيام — تابع "تحليلات" ولا تحكم من لحظة.',
    bodyEn: 'A single value is an instant snapshot influenced by everything. Real control shows in your multi-day average and trend — watch "Insights" and don\'t judge by one moment.',
  ),
  HealthTip(
    id: 'lab_hba1c',
    category: TipCategoryId.monitoring,
    titleAr: 'HbA1c المخبري كل 3–6 أشهر',
    titleEn: 'Lab HbA1c every 3–6 months',
    bodyAr: 'تقدير التطبيق لـ HbA1c مؤشر مساعد لا بديل. اعمل التحليل المخبري كل 3–6 أشهر حسب توصية طبيبك وقارنه بتقدير التطبيق لفهم انحرافك.',
    bodyEn: 'The app\'s HbA1c estimate is a supporting indicator, not a replacement. Get the lab test every 3–6 months per your doctor and compare it with the app\'s estimate to understand your offset.',
  ),
  // ── الصحة النفسية / Mental wellbeing ──────────────────────────────────
  HealthTip(
    id: 'diabetes_burnout',
    category: TipCategoryId.mentalHealth,
    titleAr: 'إنهاك السكري حقيقي',
    titleEn: 'Diabetes burnout is real',
    bodyAr: 'التعب من القياسات والأدوية والمتابعة اليومية شعور طبيعي وشائع. أخفض وتيرة القياس مؤقتاً بموافقة طبيبك، وتحدث مع مختص نفسي إن استمر الشعور أسابيع.',
    bodyEn: 'Exhaustion from daily checks, meds, and management is normal and common. Temporarily lighten your checking load with your doctor\'s approval, and talk to a professional if it lasts weeks.',
  ),
  HealthTip(
    id: 'stress_glucose',
    category: TipCategoryId.mentalHealth,
    titleAr: 'التوتر يرفع السكر فعلاً',
    titleEn: 'Stress really does raise glucose',
    bodyAr: 'هرمونات التوتر ترفع السكر مباشرة وتشجع على أكل عاطفي. جرّب تنفساً عميقاً 5 دقائق، مشياً قصيراً، أو صلاة وتأمل — وجرب لاحظ الفرق بالقياس.',
    bodyEn: 'Stress hormones raise glucose directly and fuel emotional eating. Try 5 minutes of deep breathing, a short walk, or prayer and mindfulness — then observe the difference with a check.',
  ),
  HealthTip(
    id: 'sleep',
    category: TipCategoryId.mentalHealth,
    titleAr: 'النوم مهم لسكرك',
    titleEn: 'Sleep matters for glucose',
    bodyAr: 'استهدف 7–9 ساعات نوم منتظم؛ قلة النوم تزيد مقاومة الأنسولين وتشحّم هرمونات الجوع وتفسد قراءات اليوم التالي. نظّم نومك كما تنظّم وجباتك.',
    bodyEn: 'Aim for 7–9 hours of regular sleep; short sleep increases insulin resistance, spikes hunger hormones, and skews the next day\'s readings. Schedule sleep like you schedule meals.',
  ),
  HealthTip(
    id: 'no_perfection',
    category: TipCategoryId.mentalHealth,
    titleAr: 'لا تسعَ للكمال',
    titleEn: 'Skip perfectionism',
    bodyAr: 'قراءة مرتفعة واحدة أو وجبة متأخرة ليست فشلاً. الانتباه للاتجاه العام أساسي، والذنب يرهقك أكثر مما ينفعك. احتفل بالتحسن الصغير.',
    bodyEn: 'One high reading or a late meal is not failure. What counts is the overall trend — and guilt tires you more than it helps. Celebrate small wins.',
  ),
  // ── صيام رمضان / Ramadan fasting ──────────────────────────────────────
  HealthTip(
    id: 'fasting_medical_review',
    category: TipCategoryId.ramadan,
    titleAr: 'استشر طبيبك قبل رمضان',
    titleEn: 'See your doctor before Ramadan',
    bodyAr: 'قبل الصيام بأسابيع، راجع طبيبك لضبط الأدوية والأنسولين وفق أوقات الإفطار والسحور — خاصة لو كنت على جرعات أنسولين متعددة أو أدوية قوية خافضة للسكر.',
    bodyEn: 'Weeks before fasting, review medication and insulin timing with your doctor to fit iftar and suhoor — especially on multiple insulin doses or strong glucose-lowering drugs.',
  ),
  HealthTip(
    id: 'suhoor_slow_carbs',
    category: TipCategoryId.ramadan,
    titleAr: 'سحور بطيء الامتصاص',
    titleEn: 'Slow-digesting suhoor',
    bodyAr: 'اجعل السحور وجبة متأخرة قدر الإمكان غنية بالحبوب الكاملة والبروتين والخضار (فول، زبادة، شوفان، خبز أسمر) وابعد السكريات السريعة التي تصرف طاقتك بالساعات الأولى.',
    bodyEn: 'Make suhoor as late as possible with whole grains, protein, and vegetables (foul, yogurt, oats, brown bread), and skip fast sugars that fade in the first hours.',
  ),
  HealthTip(
    id: 'hydration_window',
    category: TipCategoryId.ramadan,
    titleAr: 'وزّع الماء بين الإفطار والسحور',
    titleEn: 'Spread water between iftar and suhoor',
    bodyAr: 'احرص على 8–12 كوب ماء موزعة على ساعات الليل بدل دفعة واحدة بعد الإفطار، واستخدم عدّاد الماء في هذا التطبيق لمتابعة كميتك اليومية.',
    bodyEn: 'Aim for 8–12 cups of water spread over the night rather than one burst after iftar — and use this app\'s water tracker to follow your daily amount.',
  ),
  HealthTip(
    id: 'testing_does_not_break_fast',
    category: TipCategoryId.ramadan,
    titleAr: 'قياس السكر لا يفطر',
    titleEn: 'Testing does not break the fast',
    bodyAr: 'فحص السكر بالإبرة أو الجهاز لا يبطل الصيام عند الجمهور من الفقهاء وجمعيات السكري. قِس كلما شعرت بأعراض هبوط أو ارتفاع ولا تتردد.',
    bodyEn: 'Fingerstick or meter checks do not break the fast according to mainstream fatwa bodies and diabetes associations. Check whenever you feel high or low symptoms — don\'t hesitate.',
  ),
  HealthTip(
    id: 'when_to_break_fast',
    category: TipCategoryId.ramadan,
    titleAr: 'متى تُفطر فوراً؟',
    titleEn: 'When to break the fast immediately',
    bodyAr: 'أفطر فوراً إذا: نزل سكرك دون 70، تجاوز 300، شعرت بأعراض هبوط حاد أو أعراض حماض كيتوني، أو مرضت. سلامتك مقدمة على الصيام باتفاق الفتاوى الطبية.',
    bodyEn: 'Break your fast immediately if: glucose drops below 70, exceeds 300, you feel severe hypo or ketoacidosis symptoms, or you fall ill. Safety comes before fasting per medical fatwa consensus.',
  ),
  HealthTip(
    id: 'gradual_iftar',
    category: TipCategoryId.ramadan,
    titleAr: 'إفطار تدريجي ذكي',
    titleEn: 'A smart, gradual iftar',
    bodyAr: 'ابدأ بالتمر والماء ثم الشوربة، وأكمل بعد الصلاة بالوجبة الرئيسية. تجنب القلي والحلويات الثقيلة يومياً — اجعلها أسبوعية بمقدار معقول به.',
    bodyEn: 'Start with dates and water, then soup, and continue with the main meal after prayer. Avoid fried food and daily heavy desserts — make them a reasonable weekly treat.',
  ),
];

/// Deterministic "tip of the day" — stable for a given calendar day so the
/// Home card and any re-open of the tips screen agree.
HealthTip tipOfTheDay(DateTime now) =>
    kHealthTips[now.difference(DateTime(now.year, 1, 1)).inDays %
        kHealthTips.length];
