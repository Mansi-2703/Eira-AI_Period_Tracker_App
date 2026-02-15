import 'dart:math';
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/hercycle_palette.dart';

const List<Color> _appPalette = [
  Color(0xFFEABFFA),
  Color(0xFFCB5DF1),
  Color(0xFF9F21E3),
  Color(0xFF8C07DD),
];

class PredictionCharts extends StatelessWidget {
  final List<dynamic> cycles;
  final Map<String, dynamic>? prediction;

  const PredictionCharts({super.key, required this.cycles, this.prediction});

  List<_LabeledCycle> get _recentCycles {
    final filtered = cycles.take(8).toList();
    return filtered.map((item) {
      final label = (item['start_date'] ?? '').toString();
      return _LabeledCycle(
        label: label.isNotEmpty ? label.split('T').first : 'Cycle',
        cycleLength: _parseDouble(item['cycle_length'], fallback: 28),
        periodLength: _parseDouble(item['period_length'], fallback: 5),
      );
    }).toList();
  }

  static double _parseDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  double get _confidence =>
      double.tryParse(prediction?["confidence"]?.toString() ?? "") ?? 0.0;

  double get _stability =>
      (prediction?["quiz_insights"]?["stability_score"] is num)
      ? prediction!["quiz_insights"]["stability_score"].toDouble()
      : 0.0;

  double get _risk =>
      (prediction?["quiz_insights"]?["symptom_risk_score"] is num)
      ? prediction!["quiz_insights"]["symptom_risk_score"].toDouble()
      : 0.0;

  double get _healthScore => ((1 - _risk) * 0.6) + (_stability * 0.4);

  void _openHealthReport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return HealthReportSheet(
          confidence: _confidence,
          stability: _stability,
          risk: _risk,
          cycles: _recentCycles,
          prediction: prediction,
        );
      },
    );
  }

  void _showChartDetails(
    BuildContext context, {
    required String title,
    required String description,
    required List<String> highlights,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChartDetailSheet(
          title: title,
          description: description,
          highlights: highlights,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final labeledCycles = _recentCycles;
    if (labeledCycles.isEmpty) {
      return const SizedBox.shrink();
    }

    final cycleValues = labeledCycles.map((e) => e.cycleLength).toList();
    final periodValues = labeledCycles.map((e) => e.periodLength).toList();
    final intensityValues = labeledCycles.map((e) {
      final ratio = e.periodLength / (e.cycleLength == 0 ? 1 : e.cycleLength);
      return ratio.clamp(0.0, 1.0);
    }).toList();

    final averageCycle =
        cycleValues.reduce((a, b) => a + b) / cycleValues.length;
    final averagePeriod =
        periodValues.reduce((a, b) => a + b) / periodValues.length;
    final maxCycle = cycleValues.reduce(max);
    final minCycle = cycleValues.reduce(min);
    final latestCycle = cycleValues.first.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChartCard(
          title: "Cycle length trend",
          subtitle: "21–35 day normal window highlighted",
          onTap: () => _showChartDetails(
            context,
            title: "Cycle length trend",
            description:
                "We compare every logged cycle length against the healthy 21–35 day band so you can spot drift before it becomes a pattern.",
            highlights: [
              "Average cycle ${averageCycle.round()} days",
              "Longest ${maxCycle.round()} days · Shortest ${minCycle.round()} days",
              "Last logged cycle ${latestCycle} days",
            ],
          ),
          child: CycleLengthChartContent(
            values: cycleValues,
            labels: labeledCycles.map((e) => e.label).toList(),
            lowerBound: 21,
            upperBound: 35,
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: "Period length history",
          subtitle: "Flow duration tracked over time",
          onTap: () => _showChartDetails(
            context,
            title: "Period length history",
            description:
                "Period lengths change in response to stress, illness, or hormone shifts. Tracking each cycle keeps you prepared.",
            highlights: [
              "Average flow ${averagePeriod.round()} days",
              "Longest flow ${periodValues.reduce(max).round()} days",
              "Shortest flow ${periodValues.reduce(min).round()} days",
            ],
          ),
          child: PeriodLengthChartContent(
            values: periodValues,
            labels: labeledCycles.map((e) => e.label).toList(),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: "Period intensity",
          subtitle: "Heavier flows rise higher",
          onTap: () => _showChartDetails(
            context,
            title: "Period intensity",
            description:
                "Intensity blends your flow days with the cycle duration. Notice sharp spikes—those are cues to log symptoms.",
            highlights: [
              "Latest intensity ${(intensityValues.first * 100).round()}%",
              "Lowest intensity ${(intensityValues.reduce(min) * 100).round()}%",
              "Highest intensity ${(intensityValues.reduce(max) * 100).round()}%",
            ],
          ),
          child: SizedBox(
            height: 340,
            child: PeriodIntensityAreaChart(
              values: intensityValues,
              labels: labeledCycles.map((e) => e.label).toList(),
              currentPhase: prediction?['current_phase']?.toString(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: "Cycle health analysis",
          subtitle: "Tap for full breakdown",
          onTap: () => _openHealthReport(context),
          child: SizedBox(
            height: 280,
            child: CycleHealthCircle(
              healthScore: _healthScore,
              onTap: () => _openHealthReport(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _LabeledCycle {
  final String label;
  final double cycleLength;
  final double periodLength;

  _LabeledCycle({
    required this.label,
    required this.cycleLength,
    required this.periodLength,
  });
}

class ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback? onTap;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      colors: [_appPalette[0], _appPalette[1], _appPalette[2]],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Material(
      borderRadius: BorderRadius.circular(24),
      elevation: 6,
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: HerCyclePalette.magenta.withOpacity(0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null)
                        const Icon(Icons.info_outline, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: child,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CycleLengthChartContent extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double lowerBound;
  final double upperBound;

  const CycleLengthChartContent({
    super.key,
    required this.values,
    required this.labels,
    required this.lowerBound,
    required this.upperBound,
  });

  @override
  Widget build(BuildContext context) {
    final average = values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average cycle ${average.round()} days',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: CycleLengthLineChart(
            values: values,
            labels: labels,
            lowerBound: lowerBound,
            upperBound: upperBound,
          ),
        ),
      ],
    );
  }
}

class CycleLengthLineChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final double lowerBound;
  final double upperBound;

  const CycleLengthLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.lowerBound,
    required this.upperBound,
  });

  @override
  State<CycleLengthLineChart> createState() => _CycleLengthLineChartState();
}

class _CycleLengthLineChartState extends State<CycleLengthLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<FlSpot> _animatedSpots() {
    final factor = _controller.value;
    return widget.values.asMap().entries.map((entry) {
      final animated = lerpDouble(0, entry.value, factor) ?? entry.value;
      return FlSpot(entry.key.toDouble(), animated);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const Center(
        child: Text(
          'Add a few cycles to see the trend.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = _animatedSpots();
    final maxVal = widget.values.reduce(max);
    final minVal = widget.values.reduce(min);
    final upperY = max(widget.upperBound, maxVal) * 1.05;
    final lowerY = min(widget.lowerBound, minVal) * 0.9;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final highlightedLine = _activeSegment(spots);
        return LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBorderRadius: BorderRadius.circular(12),
                tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                getTooltipColor: (_) => HerCyclePalette.deep.withOpacity(0.9),
                getTooltipItems: (spots) => spots
                    .map(
                      (spot) => LineTooltipItem(
                        "${widget.labels.elementAt(spot.spotIndex).split('-').last}  · ${spot.y.toStringAsFixed(1)}d",
                        const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
              touchCallback: (event, response) {
                final spots = response?.lineBarSpots;
                if (spots == null || spots.isEmpty) {
                  setState(() => _selectedIndex = null);
                  return;
                }
                setState(() {
                  _selectedIndex = spots.first.spotIndex;
                });
              },
            ),
            minX: 0,
            maxX: spots.length > 1 ? spots.length - 1.0 : 1.0,
            minY: lowerY,
            maxY: upperY,
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(show: false),
            rangeAnnotations: RangeAnnotations(
              horizontalRangeAnnotations: [
                HorizontalRangeAnnotation(
                  y1: widget.lowerBound,
                  y2: widget.upperBound,
                  color: HerCyclePalette.blush.withOpacity(0.25),
                ),
              ],
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: HerCyclePalette.magenta,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      final isActive = index == _selectedIndex;
                      return FlDotCirclePainter(
                        radius: isActive ? 7 : 4,
                        color: isActive ? Colors.white : HerCyclePalette.magenta,
                        strokeWidth: isActive ? 4 : 1.5,
                        strokeColor: HerCyclePalette.magenta,
                      );
                    },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: HerCyclePalette.magenta.withOpacity(0.15),
                ),
              ),
              if (highlightedLine != null)
                highlightedLine,
            ],
          ),
        );
      },
    );
  }

  LineChartBarData? _activeSegment(List<FlSpot> spots) {
    if (_selectedIndex == null ||
        _selectedIndex! >= spots.length - 1 ||
        spots.isEmpty) {
      return null;
    }
    final segment = [spots[_selectedIndex!], spots[_selectedIndex! + 1]];
    return LineChartBarData(
      spots: segment,
      color: Colors.white,
      barWidth: 5,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
    );
  }

}

class PeriodLengthChartContent extends StatelessWidget {
  final List<double> values;
  final List<String> labels;

  const PeriodLengthChartContent({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final average = values.isEmpty
        ? 0
        : values.reduce((a, b) => a + b) / values.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Average flow ${average.round()} days',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PeriodLengthBarChart(
            values: values,
            labels: labels,
          ),
        ),
      ],
    );
  }
}

class PeriodLengthBarChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;

  const PeriodLengthBarChart({
    super.key,
    required this.values,
    required this.labels,
  });

  @override
  State<PeriodLengthBarChart> createState() => _PeriodLengthBarChartState();
}

class _PeriodLengthBarChartState extends State<PeriodLengthBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _selectedBar;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> _animatedValues() {
    return widget.values
        .map((value) => (lerpDouble(0, value, _controller.value) ?? value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const Center(
        child: Text(
          'Period history will populate as you log flows.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final animated = _animatedValues();
    final maxVal = widget.values.reduce(max);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => BarChart(
        BarChartData(
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBorderRadius: BorderRadius.circular(10),
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipColor: (_) => HerCyclePalette.deep.withOpacity(0.9),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = widget.labels.elementAt(groupIndex).split('-').last;
                return BarTooltipItem(
                  "$label · ${rod.toY.toStringAsFixed(0)}d",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                );
              },
            ),
            touchCallback: (event, response) {
              final index = response?.spot?.touchedBarGroupIndex;
              if (index == null) {
                setState(() => _selectedBar = null);
                return;
              }
              setState(() {
                _selectedBar = index;
              });
            },
          ),
          titlesData: const FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(animated.length, (index) {
            final value = animated[index];
            final isActive = index == _selectedBar;
            return BarChartGroupData(
              x: index,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: isActive ? 18 : 12,
                  borderRadius: BorderRadius.circular(10),
                  rodStackItems: [],
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      HerCyclePalette.deep,
                      HerCyclePalette.magenta,
                    ],
                  ),
                  borderSide: BorderSide(
                    color: isActive
                        ? Colors.white.withOpacity(0.6)
                        : HerCyclePalette.deep.withOpacity(0.4),
                    width: isActive ? 2 : 1,
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.05,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.18),
            Colors.white.withOpacity(0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: borderRadius,
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final String label;

  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: HerCyclePalette.deep, fontSize: 12),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 18,
            color: HerCyclePalette.light.withOpacity(0.6),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth * value.clamp(0.0, 1.0);
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      width: width,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.9),
                            color,
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          "${(value * 100).round()}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}


class ChartDetailSheet extends StatelessWidget {
  final String title;
  final String description;
  final List<String> highlights;

  const ChartDetailSheet({
    super.key,
    required this.title,
    required this.description,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ...highlights.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.fiber_manual_record,
                        size: 8,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: HerCyclePalette.blush,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Center(child: Text('Close')),
            ),
          ],
        ),
      ),
    );
  }
}

class PeriodIntensityAreaChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final String? currentPhase;

  const PeriodIntensityAreaChart({
    super.key,
    required this.values,
    required this.labels,
    this.currentPhase,
  });

  @override
  State<PeriodIntensityAreaChart> createState() =>
      _PeriodIntensityAreaChartState();
}

class _PeriodIntensityAreaChartState extends State<PeriodIntensityAreaChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  late List<int> _peakIndices;
  int? _touchedIndex;

  static const List<_IntensityLevel> _legend = [
    _IntensityLevel(label: 'Light', note: 'Gentle days', color: HerCyclePalette.blush),
    _IntensityLevel(label: 'Medium', note: 'Steady', color: HerCyclePalette.magenta),
    _IntensityLevel(label: 'Heavy', note: 'Peak flow', color: HerCyclePalette.deep),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
    _computePeaks();
  }

  @override
  void didUpdateWidget(covariant PeriodIntensityAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      _computePeaks();
    }
  }

  void _computePeaks() {
    final entries = widget.values.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final limit = min(3, entries.length);
    _peakIndices = entries.take(limit).map((entry) => entry.key).toList();
  }

  List<FlSpot> _animatedSpots() {
    final factor = _animation.value;
    return widget.values.asMap().entries.map((entry) {
      final animated =
          (lerpDouble(0, entry.value, factor) ?? entry.value).clamp(0.0, 1.0);
      return FlSpot(entry.key.toDouble(), animated);
    }).toList();
  }

  String get _currentSummary {
    final intensity = widget.values.isEmpty ? 0.0 : widget.values.last;
    if (intensity >= 0.75) return 'Heavy flow—consider rest and hydration.';
    if (intensity >= 0.45) return 'Medium intensity—stay mindful of symptoms.';
    return 'Light intensity—good recovery.';
  }

  String _phaseContext() {
    final phase = widget.currentPhase?.toLowerCase() ?? '';
    if (phase.contains('luteal')) {
      return 'Luteal phase supports endometrial fine-tuning—low intensity is normal.';
    }
    if (phase.contains('ovulation')) {
      return 'Ovulation phase may show minor spikes; stay hydrated.';
    }
    if (phase.contains('menstru')) {
      return 'Menstrual flow warning: log cramps and rest.';
    }
    return 'Tracking current cycle progress.';
  }

  String _intensityDescriptor(int percent) {
    if (percent >= 75) return 'Heavy';
    if (percent >= 45) return 'Medium';
    return 'Light';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.isEmpty) {
      return const Center(
        child: Text(
          'Intensity appears after a few logs.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = _animatedSpots();
    final latestIntensity = (widget.values.last * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              "Intensity snapshot",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              "$latestIntensity% ${_intensityDescriptor(latestIntensity)}",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _currentSummary,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          _phaseContext(),
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _legend
              .map((level) => _IntensityLevelBadge(level: level))
              .toList(),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.08),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.03),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    getTooltipColor: (_) =>
                        HerCyclePalette.deep.withOpacity(0.92),
                    getTooltipItems: (spots) => spots
                        .map(
                          (spot) => LineTooltipItem(
                            "${widget.labels.elementAt(spot.spotIndex).split('-').last}\n${(spot.y * 100).round()}% intensity",
                            const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        )
                        .toList(),
                  ),
                  touchCallback: (event, response) {
                    final spots = response?.lineBarSpots;
                    if (spots == null || spots.isEmpty) {
                      setState(() => _touchedIndex = null);
                      return;
                    }
                    setState(() {
                      _touchedIndex = spots.first.spotIndex;
                    });
                  },
                ),
                minX: 0,
                maxX: spots.length > 1 ? spots.length - 1.0 : 1,
                minY: 0,
                maxY: 1,
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    isStrokeCapRound: true,
                    barWidth: 4,
                    color: HerCyclePalette.magenta,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          HerCyclePalette.magenta.withOpacity(0.4),
                          HerCyclePalette.blush.withOpacity(0.15),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isPeak = _peakIndices.contains(index);
                        final isActive = index == _touchedIndex;
                        final radius = isActive
                            ? 8.0
                            : (isPeak ? 6.5 : 3.8);
                        final color = isActive
                            ? Colors.white
                            : (isPeak
                                ? HerCyclePalette.magenta
                                : HerCyclePalette.blush);
                        return FlDotCirclePainter(
                          radius: radius,
                          color: color,
                          strokeWidth: isActive ? 3 : 1.6,
                          strokeColor: HerCyclePalette.deep,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _IntensityLevel {
  final String label;
  final String note;
  final Color color;

  const _IntensityLevel({
    required this.label,
    required this.note,
    required this.color,
  });
}

class _IntensityLevelBadge extends StatelessWidget {
  final _IntensityLevel level;

  const _IntensityLevelBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: level.color.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: level.color.withOpacity(0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            level.label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            level.note,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class CycleHealthCircle extends StatefulWidget {
  final double healthScore;
  final VoidCallback? onTap;

  const CycleHealthCircle({
    super.key,
    required this.healthScore,
    this.onTap,
  });

  @override
  State<CycleHealthCircle> createState() => _CycleHealthCircleState();
}

class _CycleHealthCircleState extends State<CycleHealthCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _tone(double value) {
    if (value >= 0.75) return 'Balanced';
    if (value >= 0.4) return 'Watch trends';
    return 'Needs attention';
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.healthScore.clamp(0.0, 1.0);
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final value = _animation.value * target;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(190, 190),
                    painter: _CycleHealthArcPainter(progress: value),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(value * 100).round()}%",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _tone(target),
                        style: TextStyle(color: Colors.grey.shade300),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap for insights',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 1),
                              blurRadius: 6,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Glow highlights how close today is to your optimal cycle health.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CycleHealthArcPainter extends CustomPainter {
  final double progress;

  _CycleHealthArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 16;

    final glow = Paint()
      ..color = HerCyclePalette.magenta.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius + 8, glow);

    final baseCircle = Paint()
      ..color = HerCyclePalette.light.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, baseCircle);

    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * progress,
        colors: [
          HerCyclePalette.blush,
          HerCyclePalette.magenta,
          HerCyclePalette.deep,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      sweepPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CycleHealthArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class HealthReportSheet extends StatelessWidget {
  final double confidence;
  final double stability;
  final double risk;
  final List<_LabeledCycle> cycles;
  final Map<String, dynamic>? prediction;

  const HealthReportSheet({
    super.key,
    required this.confidence,
    required this.stability,
    required this.risk,
    required this.cycles,
    this.prediction,
  });

  String _formatDate(dynamic value) {
    if (value == null) return '—';
    if (value is DateTime) return DateFormat.yMMMd().format(value);
    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) return DateFormat.yMMMd().format(parsed);
    return value.toString();
  }

  String _cycleDay() => prediction?['cycle_day']?.toString() ?? '—';

  String _currentPhase() =>
      (prediction?['current_phase']?.toString() ?? 'Unknown').toUpperCase();

  @override
  Widget build(BuildContext context) {
    final latestCycle = cycles.isNotEmpty ? cycles.first : null;
    final cycleLength = latestCycle?.cycleLength.round() ?? 0;
    final periodLength = latestCycle?.periodLength.round() ?? 0;
    final nextPrediction =
        _formatDate(prediction?['next_period_date'] ?? prediction?['next_period']);
    final confidenceValue = confidence.clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: HerCyclePalette.light,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: HerCyclePalette.deep.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: HerCyclePalette.deep.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Phase insights',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: HerCyclePalette.deep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You are on cycle day ${_cycleDay()} · ${_currentPhase()}',
              style: const TextStyle(
                color: HerCyclePalette.magenta,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),

            // Cycle overview stats
            const Text(
              'Cycle overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HerCyclePalette.deep,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _ReportStat(
                    label: 'Cycle length',
                    value: cycleLength > 0 ? '$cycleLength days' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportStat(
                    label: 'Period length',
                    value: periodLength > 0 ? '$periodLength days' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReportStat(
                    label: 'Phase',
                    value: _currentPhase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Predictions section
            const Text(
              'Predictions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HerCyclePalette.deep,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: HerCyclePalette.deep.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Next period',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: HerCyclePalette.deep,
                        ),
                      ),
                      Text(
                        nextPrediction,
                        style: const TextStyle(
                          color: HerCyclePalette.magenta,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PredictionBadge(
                        label: 'Phase',
                        value: _currentPhase(),
                        color: HerCyclePalette.deep,
                      ),
                      _PredictionBadge(
                        label: 'Cycle day',
                        value: _cycleDay(),
                        color: HerCyclePalette.magenta,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedProgressBar(
                    value: confidenceValue,
                    color: HerCyclePalette.magenta,
                    label: 'Prediction confidence',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Stability and risk indicators
            const Text(
              'Stability & risk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: HerCyclePalette.deep,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedProgressBar(
              value: stability.clamp(0.0, 1.0),
              color: HerCyclePalette.deep,
              label: 'Stability score',
            ),
            const SizedBox(height: 12),
            AnimatedProgressBar(
              value: (1 - risk).clamp(0.0, 1.0),
              color: HerCyclePalette.magenta,
              label: 'Risk resilience',
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HerCyclePalette.deep,
                  elevation: 8,
                  shadowColor: HerCyclePalette.deep.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Close report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;

  const _ReportStat({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: HerCyclePalette.deep,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: HerCyclePalette.magenta,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PredictionBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PredictionBadge({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: HerCyclePalette.deep),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
