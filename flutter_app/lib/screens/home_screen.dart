// Home screen — latest reading hero + daily stats + recent readings list.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../themes/app_theme.dart';
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
          if (latest != null) _ReadingHero(latest: latest),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatCard(
                icon: Icons.trending_up,
                value: avg > 0 ? '$avg' : '—',
                unit: 'mg/dL',
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
  const _ReadingHero({required this.latest});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    final status = latest.status(s.targetMin, s.targetMax);
    final timeStr = DateFormat('HH:mm', s.language.code).format(latest.timestamp);

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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${latest.value}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('mg/dL',
                      style: TextStyle(color: Colors.white70, fontSize: 16)),
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
                        color: Colors.white.withOpacity(0.2),
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
                  backgroundColor: Colors.white.withOpacity(0.2),
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
                        Text('${reading.value}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 4),
                        Text('mg/dL',
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
