// Chart screen — full charts view with 3 chart types and sort controls.
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../i18n/strings.dart';
import '../models/reading.dart';
import '../models/settings.dart';
import '../providers/providers.dart';
import '../themes/app_theme.dart';
import '../utils/unit_converter.dart';
import '../widgets/reading_actions.dart';

enum _Period { today, week, month }
enum _ChartKind { area, line, bar }

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ChartView();
  }
}

class _ChartView extends StatefulWidget {
  const _ChartView();

  @override
  State<_ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<_ChartView> {
  _Period _period = _Period.week;
  _ChartKind _chartKind = _ChartKind.area;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final rProv = context.watch<ReadingsProvider>();
    final strings = AppStrings.of(context);

    final now = DateTime.now();
    final cutoff = _period == _Period.today
        ? DateTime(now.year, now.month, now.day)
        : _period == _Period.week
            ? now.subtract(const Duration(days: 7))
            : now.subtract(const Duration(days: 30));

    final filtered = rProv.rawReadings
        .where((r) => r.timestamp.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final stats = _computeStats(filtered, s);
    final sortedList = _applySort(filtered, rProv.sortOrder);

    return Scaffold(
      appBar: AppBar(title: Text(strings.chart)),
      body: filtered.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(strings.noDataPeriod,
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Period selector
                _segmented<_Period>(
                  value: _period,
                  values: [
                    (_Period.today, strings.get('period_today')),
                    (_Period.week, strings.get('period_week')),
                    (_Period.month, strings.get('period_month')),
                  ],
                  onChanged: (v) => setState(() => _period = v),
                ),
                const SizedBox(height: 12),

                // Chart kind selector
                _segmented<_ChartKind>(
                  value: _chartKind,
                  values: [
                    (_ChartKind.area, s.language == Language.ar ? 'منحنى' : 'Area'),
                    (_ChartKind.line, s.language == Language.ar ? 'خطي' : 'Line'),
                    (_ChartKind.bar, s.language == Language.ar ? 'أعمدة' : 'Bar'),
                  ],
                  onChanged: (v) => setState(() => _chartKind = v),
                ),
                const SizedBox(height: 16),

                // Chart card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(strings.glucoseChart,
                                style: Theme.of(context).textTheme.titleLarge),
                            Text('${filtered.length} ${strings.statReadings}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 240,
                          child: _chart(filtered, s),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          children: [
                            _legendItem(const Color(0xFF10B981), '${UnitConverter.format(s.targetMin, s.unit)}-${UnitConverter.format(s.targetMax, s.unit)} ${UnitConverter.unitLabel(s.unit)}'),
                            _legendItem(const Color(0xFF10B981), strings.statInRange),
                            _legendItem(const Color(0xFFF59E0B), strings.get('status_low')),
                            _legendItem(const Color(0xFFEF4444), strings.get('status_high')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats grid
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.2,
                      children: [
                        _StatBox(value: UnitConverter.format(stats.avg, s.unit), unit: UnitConverter.unitLabel(s.unit), label: strings.statAvg, color: const Color(0xFF0D9488)),
                        _StatBox(value: UnitConverter.format(stats.min, s.unit), unit: UnitConverter.unitLabel(s.unit), label: strings.statMin, color: const Color(0xFF10B981)),
                        _StatBox(value: UnitConverter.format(stats.max, s.unit), unit: UnitConverter.unitLabel(s.unit), label: strings.statMax, color: const Color(0xFFEF4444)),
                        _StatBox(value: '${stats.inRangePct}%', unit: '', label: strings.statInRange, color: const Color(0xFF10B981)),
                        _StatBox(value: UnitConverter.format(stats.range, s.unit), unit: UnitConverter.unitLabel(s.unit), label: s.language == Language.ar ? 'المدى' : 'Range', color: Colors.grey),
                        _StatBox(value: '${stats.count}', unit: '', label: strings.statReadings, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sort selector
                Text('${strings.sortBy}:',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _sortChip(SortOrder.newest, strings.get('sort_newest'), rProv),
                    _sortChip(SortOrder.oldest, strings.get('sort_oldest'), rProv),
                    _sortChip(SortOrder.highest, strings.get('sort_highest'), rProv),
                    _sortChip(SortOrder.lowest, strings.get('sort_lowest'), rProv),
                  ],
                ),
                const SizedBox(height: 16),

                // Readings list
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text('${strings.recentReadings} (${sortedList.length})',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        ...sortedList.map((r) => _ReadingListTile(reading: r)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _segmented<T>({
    required T value,
    required List<(T, String)> values,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: values.map((v) {
          final selected = v.$1 == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(v.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Theme.of(context).colorScheme.primary : null,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  v.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _sortChip(SortOrder order, String label, ReadingsProvider prov) {
    final selected = prov.sortOrder == order;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => prov.setSort(order),
    );
  }

  Widget _chart(List<Reading> data, Settings s) {
    if (data.isEmpty) {
      return Center(
        child: Text(AppStrings.of(context).noDataPeriod,
            style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value.toDouble());
    }).toList();

    final minY = 40.0;
    final maxY = 300.0;
    final gridColor = Colors.grey.shade200;
    final textColor = Colors.grey.shade600;
    final lineColor = Theme.of(context).colorScheme.primary;

    if (_chartKind == _ChartKind.bar) {
      return BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${UnitConverter.format(rod.toY.round(), s.unit)} ${UnitConverter.unitLabel(s.unit)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          titlesData: _titlesData(data, textColor, s),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [3, 3]),
          ),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
            final status = e.value.status(s.targetMin, s.targetMax);
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value.toDouble(),
                  color: statusColor(status),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: s.targetMin.toDouble(), color: const Color(0xFF10B981), strokeWidth: 1, dashArray: [4, 4]),
              HorizontalLine(y: s.targetMax.toDouble(), color: const Color(0xFF10B981), strokeWidth: 1, dashArray: [4, 4]),
            ],
          ),
        ),
      );
    }

    // Line or Area
    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((spot) {
              return LineTooltipItem(
                '${UnitConverter.format(spot.y.round(), s.unit)} ${UnitConverter.unitLabel(s.unit)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList(),
          ),
        ),
        titlesData: _titlesData(data, textColor, s),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [3, 3]),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(y: s.targetMin.toDouble(), color: const Color(0xFF10B981), strokeWidth: 1, dashArray: [4, 4]),
            HorizontalLine(y: s.targetMax.toDouble(), color: const Color(0xFF10B981), strokeWidth: 1, dashArray: [4, 4]),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: _chartKind == _ChartKind.area,
            color: lineColor,
            barWidth: 2.5,
            dotData: FlDotData(show: true, getDotPainter: (spot, _, __, ___) {
              final r = data[spot.x.round()];
              final st = r.status(s.targetMin, s.targetMax);
              return FlDotCirclePainter(radius: 3, color: statusColor(st));
            }),
            belowBarData: _chartKind == _ChartKind.area
                ? BarAreaData(
                    show: true,
                    color: lineColor.withValues(alpha: 0.15),
                  )
                : BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  FlTitlesData _titlesData(List<Reading> data, Color textColor, Settings s) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: 50,
          getTitlesWidget: (v, _) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('${v.round()}',
                style: TextStyle(fontSize: 10, color: textColor)),
          ),
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: (data.length / 5).ceil().toDouble().clamp(1, double.infinity),
          getTitlesWidget: (v, _) {
            final i = v.round();
            if (i < 0 || i >= data.length) return const SizedBox();
            final r = data[i];
            final fmt = _period == _Period.today
                ? DateFormat('HH:mm', s.language.code)
                : DateFormat('d/M', s.language.code);
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(fmt.format(r.timestamp),
                  style: TextStyle(fontSize: 10, color: textColor)),
            );
          },
        ),
      ),
    );
  }

  _Stats _computeStats(List<Reading> list, Settings s) {
    if (list.isEmpty) {
      return _Stats(avg: 0, min: 0, max: 0, inRangePct: 0, count: 0, range: 0);
    }
    final values = list.map((r) => r.value).toList();
    final inRange = list
        .where((r) => r.status(s.targetMin, s.targetMax) == ReadingStatus.inRange)
        .length;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return _Stats(
      avg: (values.fold<int>(0, (s, v) => s + v) / values.length).round(),
      min: min,
      max: max,
      inRangePct: ((inRange / list.length) * 100).round(),
      count: list.length,
      range: max - min,
    );
  }

  List<Reading> _applySort(List<Reading> list, SortOrder order) {
    final copy = List<Reading>.from(list);
    switch (order) {
      case SortOrder.newest:
        copy.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        break;
      case SortOrder.oldest:
        copy.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        break;
      case SortOrder.highest:
        copy.sort((a, b) => b.value.compareTo(a.value));
        break;
      case SortOrder.lowest:
        copy.sort((a, b) => a.value.compareTo(b.value));
        break;
    }
    return copy;
  }
}

class _Stats {
  final int avg;
  final int min;
  final int max;
  final int inRangePct;
  final int count;
  final int range;
  _Stats({
    required this.avg,
    required this.min,
    required this.max,
    required this.inRangePct,
    required this.count,
    required this.range,
  });
}

class _StatBox extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final Color color;
  const _StatBox({
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        if (unit.isNotEmpty)
          Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.2)),
      ],
    );
  }
}

class _ReadingListTile extends StatelessWidget {
  final Reading reading;
  const _ReadingListTile({required this.reading});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProviderState>().settings;
    final strings = AppStrings.of(context);
    final status = reading.status(s.targetMin, s.targetMax);
    final fmt = DateFormat('d MMM HH:mm', s.language.code);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(UnitConverter.format(reading.value, s.unit),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(UnitConverter.unitLabel(s.unit), style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor(status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(strings.statusLabel(status),
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor(status))),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${strings.readingType(reading.type)}${reading.notes != null && reading.notes!.isNotEmpty ? ' · ${reading.notes}' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(fmt.format(reading.timestamp),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(width: 4),
          ReadingActions(reading: reading, compact: true),
        ],
      ),
    );
  }
}
