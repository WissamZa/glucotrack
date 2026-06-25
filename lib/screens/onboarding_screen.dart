// Onboarding screen — 3 steps:
// 1. Choose language (AR/EN)
// 2. Choose display style (Classic/Modern/Elder)
// 3. Enter name + diabetes type
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/settings.dart';
import '../providers/providers.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  Language _lang = Language.ar;
  ThemeStyle _style = ThemeStyle.classic;
  DiabetesType _dtype = DiabetesType.type2;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() => setState(() => _step++);
  void _prev() => setState(() => _step = _step > 0 ? _step - 1 : 0);

  Future<void> _finish() async {
    final prov = context.read<SettingsProviderState>();
    await prov.persist(Settings(
      language: _lang,
      theme: _style,
      diabetesType: _dtype,
      userName: _nameCtrl.text.trim().isEmpty
          ? (_lang == Language.ar ? 'صديقي' : 'Friend')
          : _nameCtrl.text.trim(),
      onboarded: true,
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  final active = i == _step;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 32 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _step == 0
                      ? _step0(strings)
                      : _step == 1
                          ? _step1(strings)
                          : _step2(strings, s),
                ),
              ),
            ),
            // Footer buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _prev,
                      child: Text(strings.back),
                    ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _step == 2 ? _finish : _next,
                      child: Text(
                        _step == 2
                            ? strings.getStarted
                            : (_step == 0
                                ? (_lang == Language.ar ? 'التالي' : 'Next')
                                : (_lang == Language.ar ? 'التالي' : 'Next')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === Step 0: Language ===
  Widget _step0(AppStrings strings) {
    return Center(
      key: const ValueKey(0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(56),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 56),
          ),
          const SizedBox(height: 24),
          Text(strings.appName,
              style: Theme.of(context).textTheme.headlineLarge,),
          const SizedBox(height: 8),
          Text(strings.appTagline,
              style: TextStyle(color: Colors.grey.shade600),),
          const SizedBox(height: 40),
          Text(strings.chooseLanguage,
              style: Theme.of(context).textTheme.titleLarge,),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _langBtn('🇸🇦', 'العربية', Language.ar)),
              const SizedBox(width: 12),
              Expanded(child: _langBtn('🇬🇧', 'English', Language.en)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String flag, String label, Language lang) {
    final selected = _lang == lang;
    return InkWell(
      onTap: () => setState(() => _lang = lang),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),),
          ],
        ),
      ),
    );
  }

  // === Step 1: Display style ===
  Widget _step1(AppStrings strings) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(strings.chooseStyle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,),
          const SizedBox(height: 8),
          Text(
            _lang == Language.ar
                ? 'يمكنك تغييره لاحقاً من الإعدادات'
                : 'You can change it later in settings',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          _styleCard(
            ThemeStyle.classic,
            strings.styleClassic,
            strings.styleClassicDesc,
            Icons.medical_services,
            const [Color(0xFF0D9488), Colors.white],
          ),
          _styleCard(
            ThemeStyle.modern,
            strings.styleModern,
            strings.styleModernDesc,
            Icons.nightlight,
            const [Color(0xFFD946EF), Color(0xFF22D3EE)],
          ),
          _styleCard(
            ThemeStyle.elder,
            strings.styleElder,
            strings.styleElderDesc,
            Icons.wb_sunny,
            const [Color(0xFF0F172A), Color(0xFFF8FAFC)],
          ),
        ],
      ),
    );
  }

  Widget _styleCard(
    ThemeStyle style,
    String title,
    String desc,
    IconData icon,
    List<Color> colors,
  ) {
    final selected = _style == style;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _style = style),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16,),),
                    const SizedBox(height: 2),
                    Text(desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,),
            ],
          ),
        ),
      ),
    );
  }

  // === Step 2: Name + Diabetes type ===
  Widget _step2(AppStrings strings, Settings current) {
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.monitor_heart,
                color: Theme.of(context).colorScheme.primary, size: 32,),
          ),
          Text(strings.welcome,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,),
          const SizedBox(height: 24),
          Text(strings.yourName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: _lang == Language.ar ? 'اكتب اسمك' : 'Enter your name',
            ),
          ),
          const SizedBox(height: 24),
          Text(strings.yourDiabetesType,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _dtypeBtn(DiabetesType.type1, strings.get('diabetes_type1'))),
              const SizedBox(width: 8),
              Expanded(child: _dtypeBtn(DiabetesType.type2, strings.get('diabetes_type2'))),
              const SizedBox(width: 8),
              Expanded(child: _dtypeBtn(DiabetesType.gestational, strings.get('diabetes_gestational'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dtypeBtn(DiabetesType t, String label) {
    final selected = _dtype == t;
    return InkWell(
      onTap: () => setState(() => _dtype = t),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
      ),
    );
  }
}
