// Bundled Saudi-market medication reference — offline default source.
//
// A curated list of the most commonly used registered products in Saudi
// Arabia (brand name in Arabic + English, form, strength, active
// ingredient). Ships with the app so drug search works with zero network
// and zero registration. This is a starting library of common products, not
// the full SFDA register; the international sources (RxNorm / openFDA) can
// be selected in the Medications tab for anything else.
import '../models/medication_info.dart';

class SaudiDrug {
  final String id;
  final String nameEn;
  final String nameAr;
  final String formKey; // tablet/capsule/ml/drops/spray/cream/injection/units
  final String strength;
  final String ingredient;

  const SaudiDrug({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.formKey,
    required this.strength,
    required this.ingredient,
  });

  MedicationInfo toInfo() => MedicationInfo(
    source: 'saudi',
    rxcui: 'saudi:$id',
    name: nameEn,
    synonym: nameAr,
    doseForm: formKey,
    strength: strength,
    tty: 'saudi',
    fetchedAt: DateTime.now().millisecondsSinceEpoch,
  );
}

/// Normalize Arabic text for matching: unify alef forms, taa marbuta/haa,
/// yaa/alif maqsura, and strip harakat.
String normalizeArabic(String input) => input
    .replaceAll(RegExp('[\\u064B-\\u065F\\u0670]'), '')
    .replaceAll('أ', 'ا')
    .replaceAll('إ', 'ا')
    .replaceAll('آ', 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .trim()
    .toLowerCase();

const List<SaudiDrug> kSaudiDrugs = [
  // ── مسكنات وخوافض حرارة ────────────────────────────────────────────────
  SaudiDrug(
    id: 'panadol',
    nameEn: 'Panadol',
    nameAr: 'بنادول',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Paracetamol',
  ),
  SaudiDrug(
    id: 'panadol-extra',
    nameEn: 'Panadol Extra',
    nameAr: 'بنادول إكسترا',
    formKey: 'tablet',
    strength: '500/65 mg',
    ingredient: 'Paracetamol + Caffeine',
  ),
  SaudiDrug(
    id: 'adol',
    nameEn: 'Adol',
    nameAr: 'أدول',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Paracetamol',
  ),
  SaudiDrug(
    id: 'adol-drops',
    nameEn: 'Adol Drops',
    nameAr: 'قطرات أدول',
    formKey: 'drops',
    strength: '100 mg/ml',
    ingredient: 'Paracetamol',
  ),
  SaudiDrug(
    id: 'brufen',
    nameEn: 'Brufen',
    nameAr: 'بروفين',
    formKey: 'tablet',
    strength: '400 mg',
    ingredient: 'Ibuprofen',
  ),
  SaudiDrug(
    id: 'voltaren',
    nameEn: 'Voltaren',
    nameAr: 'فولتارين',
    formKey: 'tablet',
    strength: '50 mg',
    ingredient: 'Diclofenac',
  ),
  SaudiDrug(
    id: 'cataflam',
    nameEn: 'Cataflam',
    nameAr: 'كاتافلام',
    formKey: 'tablet',
    strength: '50 mg',
    ingredient: 'Diclofenac Potassium',
  ),
  SaudiDrug(
    id: 'profinal',
    nameEn: 'Profinal',
    nameAr: 'بروفينال',
    formKey: 'tablet',
    strength: '400 mg',
    ingredient: 'Ibuprofen',
  ),

  // ── مضادات حيوية ───────────────────────────────────────────────────────
  SaudiDrug(
    id: 'augmentin',
    nameEn: 'Augmentin',
    nameAr: 'أوجمنتين',
    formKey: 'tablet',
    strength: '1 g',
    ingredient: 'Amoxicillin + Clavulanic Acid',
  ),
  SaudiDrug(
    id: 'amoxil',
    nameEn: 'Amoxil',
    nameAr: 'أموكسيل',
    formKey: 'capsule',
    strength: '500 mg',
    ingredient: 'Amoxicillin',
  ),
  SaudiDrug(
    id: 'flagyl',
    nameEn: 'Flagyl',
    nameAr: 'فلاجيل',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Metronidazole',
  ),
  SaudiDrug(
    id: 'zithromax',
    nameEn: 'Zithromax',
    nameAr: 'زيثروماكس',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Azithromycin',
  ),
  SaudiDrug(
    id: 'klacid',
    nameEn: 'Klacid',
    nameAr: 'كلاسيد',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Clarithromycin',
  ),
  SaudiDrug(
    id: 'ciproxin',
    nameEn: 'Ciproxin',
    nameAr: 'سيبروكسين',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Ciprofloxacin',
  ),
  SaudiDrug(
    id: 'velosef',
    nameEn: 'Velosef',
    nameAr: 'فيلوسيف',
    formKey: 'capsule',
    strength: '500 mg',
    ingredient: 'Cephradine',
  ),
  SaudiDrug(
    id: 'zinnat',
    nameEn: 'Zinnat',
    nameAr: 'زينات',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Cefuroxime',
  ),

  // ── السكري ─────────────────────────────────────────────────────────────
  SaudiDrug(
    id: 'glucophage',
    nameEn: 'Glucophage',
    nameAr: 'جلوكوفاج',
    formKey: 'tablet',
    strength: '500 mg',
    ingredient: 'Metformin',
  ),
  SaudiDrug(
    id: 'amaryl',
    nameEn: 'Amaryl',
    nameAr: 'أماريل',
    formKey: 'tablet',
    strength: '2 mg',
    ingredient: 'Glimepiride',
  ),
  SaudiDrug(
    id: 'januvia',
    nameEn: 'Januvia',
    nameAr: 'جانوفيا',
    formKey: 'tablet',
    strength: '100 mg',
    ingredient: 'Sitagliptin',
  ),
  SaudiDrug(
    id: 'lantus',
    nameEn: 'Lantus',
    nameAr: 'لانتوس',
    formKey: 'injection',
    strength: '100 IU/ml',
    ingredient: 'Insulin Glargine',
  ),
  SaudiDrug(
    id: 'mixtard',
    nameEn: 'Mixtard 30',
    nameAr: 'ميكتارد 30',
    formKey: 'injection',
    strength: '100 IU/ml',
    ingredient: 'Human Insulin',
  ),
  SaudiDrug(
    id: 'novorapid',
    nameEn: 'NovoRapid',
    nameAr: 'نوفورابيد',
    formKey: 'injection',
    strength: '100 IU/ml',
    ingredient: 'Insulin Aspart',
  ),
  SaudiDrug(
    id: 'actrapid',
    nameEn: 'Actrapid',
    nameAr: 'أكتارابيد',
    formKey: 'injection',
    strength: '100 IU/ml',
    ingredient: 'Human Insulin',
  ),

  // ── الضغط والقلب ───────────────────────────────────────────────────────
  SaudiDrug(
    id: 'concor',
    nameEn: 'Concor',
    nameAr: 'كونكور',
    formKey: 'tablet',
    strength: '5 mg',
    ingredient: 'Bisoprolol',
  ),
  SaudiDrug(
    id: 'amlor',
    nameEn: 'Amlor',
    nameAr: 'أملور',
    formKey: 'capsule',
    strength: '5 mg',
    ingredient: 'Amlodipine',
  ),
  SaudiDrug(
    id: 'norvasc',
    nameEn: 'Norvasc',
    nameAr: 'نورفاسك',
    formKey: 'tablet',
    strength: '5 mg',
    ingredient: 'Amlodipine',
  ),
  SaudiDrug(
    id: 'cozaar',
    nameEn: 'Cozaar',
    nameAr: 'كوزار',
    formKey: 'tablet',
    strength: '50 mg',
    ingredient: 'Losartan',
  ),
  SaudiDrug(
    id: 'diovan',
    nameEn: 'Diovan',
    nameAr: 'ديوفان',
    formKey: 'tablet',
    strength: '160 mg',
    ingredient: 'Valsartan',
  ),
  SaudiDrug(
    id: 'aspirin-protect',
    nameEn: 'Aspirin Protect',
    nameAr: 'أسبرين بروتكت',
    formKey: 'tablet',
    strength: '81 mg',
    ingredient: 'Acetylsalicylic Acid',
  ),
  SaudiDrug(
    id: 'plavix',
    nameEn: 'Plavix',
    nameAr: 'بلافيكس',
    formKey: 'tablet',
    strength: '75 mg',
    ingredient: 'Clopidogrel',
  ),
  SaudiDrug(
    id: 'lipitor',
    nameEn: 'Lipitor',
    nameAr: 'ليبيتور',
    formKey: 'tablet',
    strength: '20 mg',
    ingredient: 'Atorvastatin',
  ),
  SaudiDrug(
    id: 'crestor',
    nameEn: 'Crestor',
    nameAr: 'كريستور',
    formKey: 'tablet',
    strength: '10 mg',
    ingredient: 'Rosuvastatin',
  ),
  SaudiDrug(
    id: 'capoten',
    nameEn: 'Capoten',
    nameAr: 'كابوتين',
    formKey: 'tablet',
    strength: '25 mg',
    ingredient: 'Captopril',
  ),

  // ── الجهاز الهضمي ─────────────────────────────────────────────────────
  SaudiDrug(
    id: 'nexium',
    nameEn: 'Nexium',
    nameAr: 'نكسيوم',
    formKey: 'tablet',
    strength: '40 mg',
    ingredient: 'Esomeprazole',
  ),
  SaudiDrug(
    id: 'omez',
    nameEn: 'Omez',
    nameAr: 'أوميز',
    formKey: 'capsule',
    strength: '20 mg',
    ingredient: 'Omeprazole',
  ),
  SaudiDrug(
    id: 'gaviscon',
    nameEn: 'Gaviscon',
    nameAr: 'جافيسكون',
    formKey: 'ml',
    strength: 'suspension',
    ingredient: 'Alginate + Antacids',
  ),
  SaudiDrug(
    id: 'motilium',
    nameEn: 'Motilium',
    nameAr: 'موتيليوم',
    formKey: 'tablet',
    strength: '10 mg',
    ingredient: 'Domperidone',
  ),
  SaudiDrug(
    id: 'buscopan',
    nameEn: 'Buscopan',
    nameAr: 'بوسكوبان',
    formKey: 'tablet',
    strength: '10 mg',
    ingredient: 'Hyoscine Butylbromide',
  ),
  SaudiDrug(
    id: 'dulcolax',
    nameEn: 'Dulcolax',
    nameAr: 'دولكولاك',
    formKey: 'tablet',
    strength: '5 mg',
    ingredient: 'Bisacodyl',
  ),
  SaudiDrug(
    id: 'antinal',
    nameEn: 'Antinal',
    nameAr: 'أنتينال',
    formKey: 'capsule',
    strength: '200 mg',
    ingredient: 'Nifuroxazide',
  ),

  // ── الحساسية والجهاز التنفسي ───────────────────────────────────────────
  SaudiDrug(
    id: 'claritine',
    nameEn: 'Claritine',
    nameAr: 'كلاريتين',
    formKey: 'tablet',
    strength: '10 mg',
    ingredient: 'Loratadine',
  ),
  SaudiDrug(
    id: 'telfast',
    nameEn: 'Telfast',
    nameAr: 'تلفاست',
    formKey: 'tablet',
    strength: '180 mg',
    ingredient: 'Fexofenadine',
  ),
  SaudiDrug(
    id: 'zyrtec',
    nameEn: 'Zyrtec',
    nameAr: 'زيرتك',
    formKey: 'tablet',
    strength: '10 mg',
    ingredient: 'Cetirizine',
  ),
  SaudiDrug(
    id: 'aerius',
    nameEn: 'Aerius',
    nameAr: 'أيريوس',
    formKey: 'tablet',
    strength: '5 mg',
    ingredient: 'Desloratadine',
  ),
  SaudiDrug(
    id: 'ventolin',
    nameEn: 'Ventolin Inhaler',
    nameAr: 'بخاخ فينتولين',
    formKey: 'spray',
    strength: '100 mcg/dose',
    ingredient: 'Salbutamol',
  ),
  SaudiDrug(
    id: 'singulair',
    nameEn: 'Singulair',
    nameAr: 'سينجولير',
    formKey: 'tablet',
    strength: '10 mg',
    ingredient: 'Montelukast',
  ),
  SaudiDrug(
    id: 'rhinathiol',
    nameEn: 'Rhinathiol',
    nameAr: 'ريناثيول',
    formKey: 'ml',
    strength: 'syrup',
    ingredient: 'Carbocisteine',
  ),

  // ── الغدة والهرمونات ──────────────────────────────────────────────────
  SaudiDrug(
    id: 'euthyrox',
    nameEn: 'Euthyrox',
    nameAr: 'يوتيروكس',
    formKey: 'tablet',
    strength: '100 mcg',
    ingredient: 'Levothyroxine',
  ),
  SaudiDrug(
    id: 'eltroxin',
    nameEn: 'Eltroxin',
    nameAr: 'إلتروكسين',
    formKey: 'tablet',
    strength: '50 mcg',
    ingredient: 'Levothyroxine',
  ),

  // ── فيتامينات ومكملات ─────────────────────────────────────────────────
  SaudiDrug(
    id: 'centrum',
    nameEn: 'Centrum',
    nameAr: 'سنتروم',
    formKey: 'tablet',
    strength: 'multivitamin',
    ingredient: 'Multivitamins',
  ),
  SaudiDrug(
    id: 'vitamin-d3',
    nameEn: 'Vitamin D3 50000',
    nameAr: 'فيتامين د3 50000',
    formKey: 'capsule',
    strength: '50000 IU',
    ingredient: 'Cholecalciferol',
  ),
  SaudiDrug(
    id: 'feroglobin',
    nameEn: 'Feroglobin',
    nameAr: 'فيروجلوبين',
    formKey: 'capsule',
    strength: 'iron + B12',
    ingredient: 'Iron + Vitamins',
  ),
  SaudiDrug(
    id: 'cal-mag',
    nameEn: 'Cal-Mag',
    nameAr: 'كال-ماج',
    formKey: 'tablet',
    strength: 'calcium + magnesium',
    ingredient: 'Calcium + Magnesium',
  ),
  SaudiDrug(
    id: 'folic-acid',
    nameEn: 'Folic Acid',
    nameAr: 'حمض الفوليك',
    formKey: 'tablet',
    strength: '5 mg',
    ingredient: 'Folic Acid',
  ),

  // ── أخرى شائعة ─────────────────────────────────────────────────────────
  SaudiDrug(
    id: 'bepanthen',
    nameEn: 'Bepanthen',
    nameAr: 'بيبانثين',
    formKey: 'cream',
    strength: 'ointment',
    ingredient: 'Dexpanthenol',
  ),
  SaudiDrug(
    id: 'fucidin',
    nameEn: 'Fucidin',
    nameAr: 'فيوسيدين',
    formKey: 'cream',
    strength: '2%',
    ingredient: 'Fusidic Acid',
  ),
  SaudiDrug(
    id: 'betadine',
    nameEn: 'Betadine',
    nameAr: 'بيتادين',
    formKey: 'ml',
    strength: '10%',
    ingredient: 'Povidone-Iodine',
  ),
  SaudiDrug(
    id: 'otrivin',
    nameEn: 'Otrivin',
    nameAr: 'أوتريفين',
    formKey: 'spray',
    strength: '0.1%',
    ingredient: 'Xylometazoline',
  ),
  SaudiDrug(
    id: 'strepsils',
    nameEn: 'Strepsils',
    nameAr: 'ستربسلز',
    formKey: 'tablet',
    strength: 'lozenge',
    ingredient: 'Antiseptic Lozenge',
  ),
  SaudiDrug(
    id: 'voltaren-emulgel',
    nameEn: 'Voltaren Emulgel',
    nameAr: 'جل فولتارين',
    formKey: 'cream',
    strength: '1%',
    ingredient: 'Diclofenac (topical)',
  ),
  SaudiDrug(
    id: 'serevent',
    nameEn: 'Serevent',
    nameAr: 'سيريفنت',
    formKey: 'spray',
    strength: '25 mcg/dose',
    ingredient: 'Salmeterol',
  ),
  SaudiDrug(
    id: 'pantoloc',
    nameEn: 'Pantoloc',
    nameAr: 'بانتولوك',
    formKey: 'tablet',
    strength: '40 mg',
    ingredient: 'Pantoprazole',
  ),
  SaudiDrug(
    id: 'zantac',
    nameEn: 'Zantac',
    nameAr: 'زانتاك',
    formKey: 'tablet',
    strength: '150 mg',
    ingredient: 'Ranitidine',
  ),
  SaudiDrug(
    id: 'valium',
    nameEn: 'Valium',
    nameAr: 'فاليوم',
    formKey: 'tablet',
    strength: '5 mg',
    ingredient: 'Diazepam',
  ),
  SaudiDrug(
    id: 'xanax',
    nameEn: 'Xanax',
    nameAr: 'زاناكس',
    formKey: 'tablet',
    strength: '0.5 mg',
    ingredient: 'Alprazolam',
  ),
  SaudiDrug(
    id: 'zoloft',
    nameEn: 'Zoloft',
    nameAr: 'زولوفت',
    formKey: 'tablet',
    strength: '50 mg',
    ingredient: 'Sertraline',
  ),
  SaudiDrug(
    id: 'prozac',
    nameEn: 'Prozac',
    nameAr: 'بروزاك',
    formKey: 'capsule',
    strength: '20 mg',
    ingredient: 'Fluoxetine',
  ),
  SaudiDrug(
    id: 'lyrica',
    nameEn: 'Lyrica',
    nameAr: 'ليريكا',
    formKey: 'capsule',
    strength: '75 mg',
    ingredient: 'Pregabalin',
  ),
  SaudiDrug(
    id: 'ursocol',
    nameEn: 'Ursocol',
    nameAr: 'أورسوكول',
    formKey: 'tablet',
    strength: '300 mg',
    ingredient: 'Ursodeoxycholic Acid',
  ),
  SaudiDrug(
    id: 'neurobion',
    nameEn: 'Neurobion',
    nameAr: 'نيوربيون',
    formKey: 'tablet',
    strength: 'B-complex',
    ingredient: 'Vitamin B Complex',
  ),
];

/// Search the bundled Saudi list by English or Arabic name (Arabic is
/// normalized so أ/إ/آ and ة/ه variants match).
List<SaudiDrug> searchSaudiDrugs(String query) {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final qLower = q.toLowerCase();
  final qArabic = normalizeArabic(q);
  return kSaudiDrugs.where((d) {
    if (d.nameEn.toLowerCase().contains(qLower)) return true;
    if (d.ingredient.toLowerCase().contains(qLower)) return true;
    if (normalizeArabic(d.nameAr).contains(qArabic)) return true;
    return false;
  }).toList();
}
