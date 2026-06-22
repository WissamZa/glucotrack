// Home screen — latest reading hero + daily stats + recent readings list.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../themes/app_theme.dart';
import '../utils/unit_converter.dart';
import '../utils/trend_analysis.dart';
import '../utils/hba1c_calculator.dart';
import '../widgets/reading_actions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final rProv = context.watch<ReadingsProvider>();
    final remProv = context.watch<RemindersProvider>();
    final strings = AppStrings.of(context);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final today = rProv.rawReadings.where((r) => r.timestamp.isAfter(todayStart)).toList();

    final latest = rProv.rawReadings.isEmpty ? null : rProv.rawReadings.first;
    final avg = today.isEmpty
        ? 0
        : (today.fold<int>(0, (s, r) => s + r.value) / today.length).round();
    final inRange = today
        .where((r) => r.status(s.targetMin, s.targetMax) == ReadingStatus.inRange)
        .length;
    final inRangePct = today.isEmpty ? 0 : ((inRange / today.length) * 100).round();

    // Calculate trend
    final trend = TrendAnalyzer.fromReadings(rProv.rawReadings);

    // Calculate HbA1c
    final hba1c = HbA1cCalculator.calculate(rProv.rawReadings);

    // Total insulin today
    final totalInsulin = today.fold<int>(0, (sum, r) => sum + (r.insulin ?? 0));

    final greeting = _greeting(now.hour, strings);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(greeting, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            Text(s.userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          // Insights shortcut button
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.pushNamed(context, '/insights'),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => Navigator.pushNamed(context, '/reminders'),
              ),
              if (remProv.activeCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${remProv.activeCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (latest != null) _ReadingHero(latest: latest, trend: trend, unit: s.unit),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(
                icon: Icons.trending_up,
                value: avg > 0 ? UnitConverter.format(avg, s.unit) : '—',
                unit: UnitConverter.unitLabel(s.unit),
                label: strings.avgToday,
                color: const Color(0xFF0D9488),
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.water_drop,
                value: '${today.length}',
                unit: '',
                label: strings.readingsCount,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              _StatCard(
                icon: Icons.gps_fixed,
                value: today.isNotEmpty ? '$inRangePct%' : '—',
                unit: '',
                label: strings.inRangePct,
                color: inRangePct >= 70 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              ),
            ],
          ),
          // HbA1c quick indicator
          if (hba1c != null) ...[
            const SizedBox(height: 12),
            _HbA1cQuickChip(hba1c: hba1c, strings: strings),
          ],
          // Trend indicator
          if (trend != null) ...[
            const SizedBox(height: 12),
            _TrendChip(trend: trend, strings: strings, isArabic: s.language == Language.ar),
          ],
          // Quick actions row
          const SizedBox(height: 16),
          _QuickActionsRow(strings: strings),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(strings.recentReadings,
                  style: Theme.of(context).textTheme.titleLarge),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/chart'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(strings.viewAll),
                    Icon(s.isRtl ? Icons.chevron_left : Icons.chevron_right, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rProv.readings.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.water_drop_outlined,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    Text(strings.noReadingsYet,
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(strings.addFirstReading,
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...rProv.readings.take(5).map((r) => _ReadingRow(reading: r)),
        ],
      ),
    );
  }

  String _greeting(int hour, AppStrings strings) {
    if (hour < 12) return strings.get('good_morning');
    if (hour < 17) return strings.get('good_afternoon');
    if (hour < 22) return strings.get('good_evening');
    return strings.get('good_night');
  }
}

class _ReadingHero extends StatelessWidget {
  final Reading latest;
  final TrendResult? trend;
  final GlucoseUnit unit;
  const _ReadingHero({required this.latest, this.trend, required this.unit});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    final status = latest.status(s.targetMin, s.targetMax);
    final timeStr = DateFormat('HH:mm', s.language.code).format(latest.timestamp);
    final valueDisplay = UnitConverter.format(latest.value, unit);
    final unitLabel = UnitConverter.unitLabel(unit);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF0D9488),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(strings.latestReading,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                Row(
                  children: [
                    // Trend badge on hero
                    if (trend != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        margin: const EdgeInsetsDirectional.only(end: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trend!.direction.arrow,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        strings.statusLabel(status),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(valueDisplay,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1)),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(unitLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        strings.readingType(latest.type),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(timeStr,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                FloatingActionButton.small(
                  onPressed: () => Navigator.pushNamed(context, '/add'),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HbA1cQuickChip extends StatelessWidget {
  final HbA1cResult hba1c;
  final AppStrings strings;
  const _HbA1cQuickChip({required this.hba1c, required this.strings});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/insights'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(hba1c.category.colorHex).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(hba1c.category.colorHex).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.science,
              size: 18,
              color: Color(hba1c.category.colorHex),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${strings.hba1cEstimate}: ${hba1c.percentageFormatted}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(hba1c.category.colorHex),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(hba1c.category.colorHex),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final TrendResult trend;
  final AppStrings strings;
  final bool isArabic;
  const _TrendChip({required this.trend, required this.strings, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(trend.direction.colorHex).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(trend.direction.colorHex).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Text(
            trend.direction.arrow,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(trend.direction.colorHex),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${strings.trendLabel}: ${TrendAnalyzer.getLocalizedLabel(trend.direction, isArabic)}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(trend.direction.colorHex),
              ),
            ),
          ),
          Text(
            '${trend.ratePerHour >= 0 ? "+" : ""}${trend.ratePerHour.toStringAsFixed(1)} mg/dL/h',
            style: TextStyle(
              fontSize: 12,
              color: Color(trend.direction.colorHex),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final AppStrings strings;
  const _QuickActionsRow({required this.strings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QuickActionBtn(
          icon: Icons.insights,
          label: strings.insights,
          color: const Color(0xFF3B82F6),
          onTap: () => Navigator.pushNamed(context, '/insights'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.upload_file,
          label: strings.exportData,
          color: const Color(0xFF10B981),
          onTap: () => Navigator.pushNamed(context, '/export'),
        ),
        const SizedBox(width: 8),
        _QuickActionBtn(
          icon: Icons.alarm,
          label: strings.navReminders,
          color: const Color(0xFFF59E0B),
          onTap: () => Navigator.pushNamed(context, '/reminders'),
        ),
      ],
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              if (unit.isNotEmpty)
                Text(unit,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final Reading reading;
  const _ReadingRow({required this.reading});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    final status = reading.status(s.targetMin, s.targetMax);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dayLabel;
    if (_sameDay(reading.timestamp, today)) {
      dayLabel = strings.today;
    } else if (_sameDay(reading.timestamp, yesterday)) {
      dayLabel = strings.yesterday;
    } else {
      dayLabel = DateFormat('d MMM', s.language.code).format(reading.timestamp);
    }
    final timeStr = DateFormat('HH:mm', s.language.code).format(reading.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(UnitConverter.format(reading.value, s.unit),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(UnitConverter.unitLabel(s.unit),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                    Text(
                      '${strings.readingType(reading.type)} · $dayLabel $timeStr'
                      '${reading.notes != null && reading.notes!.isNotEmpty ? ' · ${reading.notes}' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ReadingActions(reading: reading),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
