// Health tips screen — categorized patient education (AR/EN).
//
// Content comes from lib/data/health_tips.dart (bundled with the app, works
// fully offline). A medical disclaimer is always visible at the top.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/health_tips.dart';
import '../i18n/strings.dart';
import '../models/settings.dart';
import '../widgets/screen_padding.dart';

class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  TipCategoryId? _selected; // null = all categories

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);

    final tips = _selected == null
        ? kHealthTips
        : kHealthTips.where((t) => t.category == _selected).toList();

    return Scaffold(
      appBar: AppBar(title: Text(strings.tips)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _DisclaimerCard(text: strings.tipsDisclaimer),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                _categoryChip(
                  null,
                  strings.viewAllTips,
                  Icons.apps,
                  settings.language,
                ),
                for (final cat in kTipCategories)
                  _categoryChip(
                    cat.id,
                    cat.label(settings.language),
                    cat.icon,
                    settings.language,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              strings.tipsCount(tips.length),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                pushedScreenBottomClearance(context),
              ),
              itemCount: tips.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final tip = tips[i];
                return _TipCard(
                  tip: tip,
                  language: settings.language,
                  categoryLabel: kTipCategories
                      .firstWhere((c) => c.id == tip.category)
                      .label(settings.language),
                  categoryIcon: kTipCategories
                      .firstWhere((c) => c.id == tip.category)
                      .icon,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(
    TipCategoryId? id,
    String label,
    IconData icon,
    Language lang,
  ) {
    final selected = _selected == id;
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: InkWell(
        onTap: () => setState(() => _selected = id),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: selected ? Colors.white : color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  final String text;
  const _DisclaimerCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final HealthTip tip;
  final Language language;
  final String categoryLabel;
  final IconData categoryIcon;

  const _TipCard({
    required this.tip,
    required this.language,
    required this.categoryLabel,
    required this.categoryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Card(
      child: Theme(
        // Remove the divider under ExpansionTile.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(categoryIcon, size: 20, color: color),
          ),
          title: Text(
            tip.title(language),
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            categoryLabel,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          iconColor: Colors.grey.shade500,
          collapsedIconColor: Colors.grey.shade500,
          children: [
            Align(
              alignment: language.isRtl
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Text(
                tip.body(language),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.7,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
