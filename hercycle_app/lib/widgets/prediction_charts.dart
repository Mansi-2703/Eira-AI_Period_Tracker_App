import 'dart:math';
import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/hercycle_palette.dart';
import '../services/api_service.dart';
import 'daily_log_card.dart';

const List<Color> _appPalette = [
  Color(0xFFEABFFA),
  Color(0xFFCB5DF1),
  Color(0xFF9F21E3),
  Color(0xFF8C07DD),
];

// ============================================================================
// HORMONE CHART DATA MODELS & ALGORITHM
// ============================================================================

class SymptomDot {
  final int cycleDay;
  final String type;
  final String label;
  final Color color;
  SymptomDot({
    required this.cycleDay,
    required this.type,
    required this.label,
    required this.color,
  });
}

class CycleChartData {
  final int cycleLength;
  final Map<String, DateRange> phases;
  final Map<String, List<double>> hormonePoints;
  final List<SymptomDot> symptomDots;
  final int todayDay;
  CycleChartData({
    required this.cycleLength,
    required this.phases,
    required this.hormonePoints,
    required this.symptomDots,
    required this.todayDay,
  });
}

class DateRange {
  final int start, end;
  DateRange(this.start, this.end);
}

double _gaussian(double d, double mean, double sigma) =>
    exp(-0.5 * pow((d - mean) / sigma, 2));

CycleChartData? computeCycleChart(List<dynamic>? dailyLogs) {
  if (dailyLogs == null || dailyLogs.isEmpty) return null;
  final logs = <Map<String, dynamic>>[];
  for (var log in dailyLogs) {
    if (log is Map) logs.add(Map<String, dynamic>.from(log));
  }
  if (logs.isEmpty) return null;

  logs.sort((a, b) {
    final dateA = DateTime.tryParse(a['date']?.toString() ?? '');
    final dateB = DateTime.tryParse(b['date']?.toString() ?? '');
    if (dateA == null || dateB == null) return 0;
    return dateA.compareTo(dateB);
  });

  final List<DateTime> cycleStarts = [];
  for (var log in logs) {
    final flow = log['flow']?.toString().toLowerCase() ?? '';
    if (flow == 'light' || flow == 'medium' || flow == 'heavy') {
      final date = DateTime.tryParse(log['date']?.toString() ?? '');
      if (date != null) {
        if (cycleStarts.isEmpty ||
            date.difference(cycleStarts.last).inDays >= 18) {
          cycleStarts.add(date);
        }
      }
    }
  }

  if (cycleStarts.isEmpty) return null;

  final cycleStartDate = cycleStarts.last;
  int cycleLength = 28;
  if (cycleStarts.length > 1) {
    final lengths = <int>[];
    for (int i = 1; i < cycleStarts.length; i++) {
      lengths.add(cycleStarts[i].difference(cycleStarts[i - 1]).inDays);
    }
    cycleLength = (lengths.reduce((a, b) => a + b) / lengths.length)
        .round()
        .clamp(20, 45);
  }

  final today = DateTime.now();
  final daysSinceCycle = today.difference(cycleStartDate).inDays;
  final todayDay = daysSinceCycle + 1;

  int menstruationEnd = 1;
  for (var log in logs) {
    final date = DateTime.tryParse(log['date']?.toString() ?? '');
    if (date == null) continue;
    final dayNum = date.difference(cycleStartDate).inDays + 1;
    if (dayNum < 1 || dayNum > cycleLength) continue;
    final flow = log['flow']?.toString().toLowerCase() ?? '';
    if (flow == 'light' || flow == 'medium' || flow == 'heavy') {
      menstruationEnd = dayNum;
    }
  }
  menstruationEnd = min(menstruationEnd, cycleLength - 2);

  int ovulationDay = (cycleLength * 0.5).round();
  for (var log in logs) {
    final date = DateTime.tryParse(log['date']?.toString() ?? '');
    if (date == null) continue;
    final dayNum = date.difference(cycleStartDate).inDays + 1;
    if (dayNum < 1 || dayNum > cycleLength) continue;
    final symptoms = log['symptoms'];
    if (symptoms is List) {
      for (var symptom in symptoms) {
        if (symptom.toString().toLowerCase() == 'discharge') {
          ovulationDay = dayNum;
          break;
        }
      }
    }
  }

  final follicularStart = menstruationEnd + 1;
  final follicularEnd = max(1, ovulationDay - 1);
  final lutealStart = min(cycleLength, ovulationDay + 1);
  final lutealEnd = cycleLength;

  final oestradiol = <double>[];
  final progesterone = <double>[];
  final lh = <double>[];
  final fsh = <double>[];

  for (int d = 1; d <= cycleLength; d++) {
    final peak1 = _gaussian(d.toDouble(), ovulationDay.toDouble(), 2.5);
    final peak2Peak = _gaussian(
      d.toDouble(),
      (lutealStart + (lutealEnd - lutealStart) * 0.4).toDouble(),
      4.0,
    );
    final peak2 = peak2Peak * 0.45;
    oestradiol.add((peak1 + peak2).clamp(0.0, 1.0));

    if (d < ovulationDay) {
      progesterone.add(0.02);
    } else {
      final progPeak = _gaussian(
        d.toDouble(),
        (lutealStart + (lutealEnd - lutealStart) * 0.45).toDouble(),
        ((lutealEnd - lutealStart) * 0.28).toDouble(),
      );
      progesterone.add(progPeak.clamp(0.0, 1.0));
    }

    lh.add(_gaussian(d.toDouble(), ovulationDay.toDouble(), 1.2));

    final fshPeak1 =
        _gaussian(d.toDouble(), (follicularStart + 3).toDouble(), 3.5) * 0.75;
    final fshPeak2 =
        _gaussian(d.toDouble(), ovulationDay.toDouble(), 1.5) * 0.5;
    fsh.add((fshPeak1 + fshPeak2).clamp(0.0, 1.0));
  }

  final symptomDots = <SymptomDot>[];
  final moodColors = {
    'happy': const Color(0xFFFFD700),
    'calm': const Color(0xFF87CEEB),
    'anxious': const Color(0xFF9370DB),
    'irritable': const Color(0xFFFF6B6B),
    'sad': const Color(0xFF4A90E2),
    'sensitive': const Color(0xFFFF69B4),
  };
  final symptomColors = {
    'bloating': const Color(0xFFFFA500),
    'headache': const Color(0xFFDC143C),
    'breast_tender': const Color(0xFFFF1493),
    'acne': const Color(0xFF8B4513),
    'discharge': const Color(0xFF90EE90),
    'backache': const Color(0xFF704214),
    'nausea': const Color(0xFF9ACD32),
    'insomnia': const Color(0xFF191970),
    'cramps': const Color(0xFFFF0000),
  };

  for (var log in logs) {
    final date = DateTime.tryParse(log['date']?.toString() ?? '');
    if (date == null) continue;
    final dayNum = date.difference(cycleStartDate).inDays + 1;
    if (dayNum < 1 || dayNum > cycleLength) continue;

    final mood = log['mood']?.toString().toLowerCase();
    if (mood != null && mood.isNotEmpty) {
      final color = moodColors[mood] ?? const Color(0xFF999999);
      symptomDots.add(
        SymptomDot(
          cycleDay: dayNum,
          type: 'mood',
          label: mood[0].toUpperCase() + mood.substring(1),
          color: color,
        ),
      );
    }

    final symptoms = log['symptoms'];
    if (symptoms is List) {
      for (var symptom in symptoms) {
        final symptomStr = symptom.toString().toLowerCase();
        final color = symptomColors[symptomStr] ?? const Color(0xFF999999);
        final label = symptomStr
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
        symptomDots.add(
          SymptomDot(
            cycleDay: dayNum,
            type: 'symptom',
            label: label.length > 8 ? label.substring(0, 8) : label,
            color: color,
          ),
        );
      }
    }
  }

  final phases = {
    'menstrual': DateRange(1, menstruationEnd),
    'follicular': DateRange(follicularStart, follicularEnd),
    'ovulation': DateRange(ovulationDay, ovulationDay),
    'luteal': DateRange(lutealStart, lutealEnd),
  };

  return CycleChartData(
    cycleLength: cycleLength,
    phases: phases,
    hormonePoints: {
      'oestradiol': oestradiol,
      'progesterone': progesterone,
      'lh': lh,
      'fsh': fsh,
    },
    symptomDots: symptomDots,
    todayDay: todayDay,
  );
}

// ============================================================================
// HORMONE CHART PAINTER & WIDGET
// ============================================================================

class CycleChartPainter extends CustomPainter {
  final CycleChartData data;
  CycleChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 40.0, bottomPadding = 30.0;
    final chartWidth = size.width - (padding * 2),
        chartHeight = size.height - padding - bottomPadding;

    _drawPhaseBands(canvas, size, chartWidth, chartHeight, padding);
    _drawGrid(canvas, size, padding, chartWidth, chartHeight);
    _drawHormoneLines(canvas, size, padding, chartWidth, chartHeight);
    _drawSymptomDots(canvas, size, padding, chartWidth, chartHeight);
    _drawTodayMarker(canvas, size, padding, chartWidth, chartHeight);
    _drawAxes(canvas, size, padding, chartWidth, chartHeight);
  }

  void _drawPhaseBands(Canvas c, Size s, double cw, double ch, double p) {
    const phaseColors = {
      'menstrual': Color.fromARGB(20, 255, 0, 0),
      'follicular': Color.fromARGB(20, 255, 165, 0),
      'ovulation': Color.fromARGB(20, 0, 128, 0),
      'luteal': Color.fromARGB(20, 128, 0, 128),
    };
    data.phases.forEach((pn, pr) {
      final col = phaseColors[pn] ?? Colors.grey;
      final x1 = p + (pr.start / data.cycleLength) * cw,
          x2 = p + ((pr.end + 1) / data.cycleLength) * cw;
      c.drawRect(Rect.fromLTWH(x1, p, x2 - x1, ch), Paint()..color = col);
    });
  }

  void _drawGrid(Canvas c, Size s, double p, double cw, double ch) {
    final gp = Paint()
      ..color = const Color.fromARGB(30, 0, 0, 0)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 5; i++) {
      final y = p + (i / 5) * ch;
      c.drawLine(Offset(p, y), Offset(p + cw, y), gp);
    }
    for (int d = 0; d <= data.cycleLength; d += 7) {
      final x = p + (d / data.cycleLength) * cw;
      c.drawLine(Offset(x, p), Offset(x, p + ch), gp);
    }
  }

  void _drawHormoneLines(Canvas c, Size s, double p, double cw, double ch) {
    const hormoneColors = {
      'oestradiol': Color(0xFFE870C0),
      'progesterone': Color(0xFF7058D8),
      'lh': Color(0xFF58C870),
      'fsh': Color(0xFFF0A050),
    };
    data.hormonePoints.forEach((hn, pts) {
      final col = hormoneColors[hn] ?? Colors.grey;
      final paint = Paint()
        ..color = col
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (int i = 0; i < pts.length - 1; i++) {
        final x1 = p + (i / data.cycleLength) * cw, y1 = p + ch - (pts[i] * ch);
        final x2 = p + ((i + 1) / data.cycleLength) * cw,
            y2 = p + ch - (pts[i + 1] * ch);
        c.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      }
    });
  }

  void _drawSymptomDots(Canvas c, Size s, double p, double cw, double ch) {
    final by = p + ch + 10;
    for (var dot in data.symptomDots) {
      final x = p + (dot.cycleDay / data.cycleLength) * cw;
      c.drawCircle(Offset(x, by), 4, Paint()..color = dot.color);
      c.drawCircle(
        Offset(x, by),
        4,
        Paint()
          ..color = dot.color.withOpacity(0.5)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawTodayMarker(Canvas c, Size s, double p, double cw, double ch) {
    if (data.todayDay < 1 || data.todayDay > data.cycleLength) return;
    final x = p + (data.todayDay / data.cycleLength) * cw;
    final lp = Paint()
      ..color = const Color(0xFF3D0066).withOpacity(0.6)
      ..strokeWidth = 1.5;
    var cy = p;
    while (cy < p + ch) {
      c.drawLine(Offset(x, cy), Offset(x, cy + 3), lp);
      cy += 6;
    }

    final tp = TextPainter(
      text: TextSpan(
        text: 'Day ${data.todayDay}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();
    final pr = Rect.fromLTWH(x - (tp.width + 8) / 2, p - 26, tp.width + 8, 18);
    c.drawRRect(
      RRect.fromRectAndRadius(pr, const Radius.circular(8)),
      Paint()..color = const Color(0xFF3D0066),
    );
    tp.paint(c, Offset(pr.left + 4, pr.top + (18 - tp.height) / 2));
  }

  void _drawAxes(Canvas c, Size s, double p, double cw, double ch) {
    final ap = Paint()
      ..color = Color.fromARGB(80, 0, 0, 0)
      ..strokeWidth = 1;
    final ex = p + cw, ey = p + ch;
    c.drawLine(Offset(p, p), Offset(p, ey), ap);
    c.drawLine(Offset(p, ey), Offset(ex, ey), ap);

    const yl = ['100%', '80%', '60%', '40%', '20%', '0%'];
    for (int i = 0; i <= 5; i++) {
      final y = p + (i / 5) * ch;
      final tp = TextPainter(
        text: TextSpan(
          text: yl[i],
          style: const TextStyle(
            color: Color.fromARGB(100, 0, 0, 0),
            fontSize: 8,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(c, Offset(p - tp.width - 8, y - tp.height / 2));
    }

    for (int d = 0; d <= data.cycleLength; d += 7) {
      final x = p + (d / data.cycleLength) * cw;
      final tp = TextPainter(
        text: TextSpan(
          text: 'D$d',
          style: const TextStyle(
            color: Color.fromARGB(100, 0, 0, 0),
            fontSize: 8,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(c, Offset(x - tp.width / 2, ey + 6));
    }
  }

  @override
  bool shouldRepaint(CycleChartPainter oldDelegate) => oldDelegate.data != data;
}

class CycleHormoneChartCard extends StatelessWidget {
  final CycleChartData chartData;
  const CycleHormoneChartCard({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    return ChartCard(
      title: "Hormone cycle chart",
      subtitle: "Your hormones throughout your cycle",
      customGradient: const LinearGradient(
        colors: [Color(0xFFE8F5FF), Color(0xFFF0E8FF), Color(0xFFFFFFFF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
      ),
      textColor: const Color(0xFF7058D8),
      child: SizedBox(
        height: 350,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _LegendItem(
                    color: const Color(0xFFE870C0),
                    label: 'Oestradiol',
                  ),
                  _LegendItem(
                    color: const Color(0xFF7058D8),
                    label: 'Progesterone',
                  ),
                  _LegendItem(color: const Color(0xFF58C870), label: 'LH'),
                  _LegendItem(color: const Color(0xFFF0A050), label: 'FSH'),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: CustomPaint(
                  painter: CycleChartPainter(chartData),
                  size: Size.infinite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

class PredictionCharts extends StatefulWidget {
  final List<dynamic> cycles;
  final Map<String, dynamic>? prediction;

  const PredictionCharts({super.key, required this.cycles, this.prediction});

  @override
  State<PredictionCharts> createState() => _PredictionChartsState();
}

class _PredictionChartsState extends State<PredictionCharts> {
  List<dynamic>? _dailyLogs;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDailyLogs();
  }

  Future<void> _fetchDailyLogs() async {
    try {
      final logs = await ApiService.fetchDailyLogs(limit: 90);
      if (mounted)
        setState(() {
          _dailyLogs = logs;
          _isLoading = false;
        });
    } catch (e) {
      debugPrint('Error fetching daily logs: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  List<_LabeledCycle> get _recentCycles {
    final filtered = widget.cycles.take(8).toList();
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
      double.tryParse(widget.prediction?["confidence"]?.toString() ?? "") ??
      0.0;

  double get _stability =>
      (widget.prediction?["quiz_insights"]?["stability_score"] is num)
      ? widget.prediction!["quiz_insights"]["stability_score"].toDouble()
      : 0.0;

  double get _risk =>
      (widget.prediction?["quiz_insights"]?["symptom_risk_score"] is num)
      ? widget.prediction!["quiz_insights"]["symptom_risk_score"].toDouble()
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
          prediction: widget.prediction,
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
    final maxCycle = cycleValues.reduce(max);
    final minCycle = cycleValues.reduce(min);
    final latestCycle = cycleValues.first.round();

    // Compute hormone chart data
    final chartData = _isLoading ? null : computeCycleChart(_dailyLogs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily log card
        DailyLogCard(
          date: DateTime.now(),
          onLogSaved: (logData) async {
            try {
              final success = await ApiService.saveDailyLog(logData);
              if (success) {
                debugPrint('Daily log saved successfully: $logData');
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Daily log saved successfully!',
                        style: TextStyle(color: Colors.black),
                      ),
                      backgroundColor: Color(0xFFAB47BC),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                debugPrint('Failed to save daily log - Check authentication');
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Authentication failed. Please login again.',
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              }
            } catch (e) {
              debugPrint('Error saving daily log: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Network error: ${e.toString()}'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
        ),
        // Hormone chart card (if data available)
        if (chartData != null)
          Column(
            children: [
              CycleHormoneChartCard(chartData: chartData),
              const SizedBox(height: 16),
            ],
          ),
        ChartCard(
          title: "Cycle length trend",
          subtitle: "21–35 day range is healthy",
          customGradient: const LinearGradient(
            colors: [Color(0xFFFFE8F5), Color(0xFFF0E8FF), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          textColor: const Color(0xFFFF1493),
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
            average: averageCycle,
            minRecent: minCycle,
            maxRecent: maxCycle,
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: "Period intensity",
          subtitle: "Heavier flows rise higher on the chart",
          customGradient: const LinearGradient(
            colors: [Color(0xFFFFE8F5), Color(0xFFF0E8FF), Color(0xFFE8F0FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.5, 1.0],
          ),
          textColor: const Color(0xFF9B6BB8),
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
            height: 380,
            child: PeriodIntensityAreaChart(
              values: intensityValues,
              labels: labeledCycles.map((e) => e.label).toList(),
              currentPhase: widget.prediction?['current_phase']?.toString(),
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
  final LinearGradient? customGradient;
  final Color? textColor;

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.onTap,
    this.customGradient,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final gradient =
        customGradient ??
        LinearGradient(
          colors: [_appPalette[0], _appPalette[1], _appPalette[2]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    final headerTextColor = textColor ?? Colors.white;

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
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: headerTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: headerTextColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null)
                        Icon(Icons.info_outline, color: headerTextColor),
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
  final double average;
  final double minRecent;
  final double maxRecent;

  const CycleLengthChartContent({
    super.key,
    required this.values,
    required this.labels,
    required this.lowerBound,
    required this.upperBound,
    required this.average,
    required this.minRecent,
    required this.maxRecent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Panel with white background
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Average days stat
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      average.round().toString(),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B4DB8),
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'avg days',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB08AC8)),
                    ),
                  ],
                ),
                // Divider
                Container(
                  width: 1,
                  color: const Color(0xFFB48CD2).withOpacity(0.3),
                ),
                // Recent range stat
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${minRecent.round()}–${maxRecent.round()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFD87CC8),
                        height: 1.1,
                      ),
                    ),
                    const Text(
                      'recent range',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB08AC8)),
                    ),
                  ],
                ),
                // Divider
                Container(
                  width: 1,
                  color: const Color(0xFFB48CD2).withOpacity(0.3),
                ),
                // Status
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F8EE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF5BC88A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Normal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2E9E60),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'cycle status',
                      style: TextStyle(fontSize: 11, color: Color(0xFFB08AC8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Chart Container
        SizedBox(
          height: 240,
          child: CycleLengthLineChart(
            values: values,
            labels: labels,
            lowerBound: lowerBound,
            upperBound: upperBound,
          ),
        ),
        const SizedBox(height: 12),
        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Row(
            children: [
              _buildLegendItem(
                indicator: Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA8D8B8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                label: 'healthy range',
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                indicator: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD87CC8),
                      width: 2,
                    ),
                    color: Colors.white,
                  ),
                ),
                label: 'cycle length',
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                indicator: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE87AB8),
                  ),
                ),
                label: 'shortest',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Widget indicator, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFFA07AB8)),
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
      final animated = ui.lerpDouble(0, entry.value, factor) ?? entry.value;
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
        return Stack(
          children: [
            // Custom painter for day labels
            Positioned.fill(
              child: CustomPaint(
                painter: _CycleLengthLabelsPainter(
                  values: widget.values,
                  spots: spots,
                  maxY: upperY,
                  minY: lowerY,
                  selectedIndex: _selectedIndex,
                ),
              ),
            ),
            // LineChart
            LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    getTooltipColor: (_) =>
                        HerCyclePalette.deep.withOpacity(0.9),
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
                      color: const Color(0xFFA8E8C8).withOpacity(0.4),
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFFD87CC8),
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        final isActive = index == _selectedIndex;
                        final value = widget.values[index];
                        final minVal = widget.values.reduce(min);
                        final isMinimum = value == minVal;

                        // Find shortest for filled pink dot
                        Color dotColor;
                        if (isMinimum) {
                          dotColor = const Color(
                            0xFFE87AB8,
                          ); // Filled pink for shortest
                        } else if (value > widget.upperBound) {
                          dotColor = const Color(0xFFA87BE8); // Purple for high
                        } else if (value < widget.lowerBound) {
                          dotColor = const Color(
                            0xFFC060A8,
                          ); // Different purple for low
                        } else {
                          dotColor = const Color(0xFFD87CC8); // Pink for normal
                        }

                        return FlDotCirclePainter(
                          radius: isMinimum ? 6 : (isActive ? 5.5 : 5),
                          color: isMinimum ? dotColor : Colors.white,
                          strokeWidth: isMinimum ? 2 : 2,
                          strokeColor: dotColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFE87AB8).withOpacity(0.5),
                          const Color(0xFFE87AB8).withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  if (highlightedLine != null) highlightedLine,
                ],
              ),
            ),
          ],
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

// Custom painter to draw day labels on each data point
class _CycleLengthLabelsPainter extends CustomPainter {
  final List<double> values;
  final List<FlSpot> spots;
  final double maxY;
  final double minY;
  final int? selectedIndex;

  _CycleLengthLabelsPainter({
    required this.values,
    required this.spots,
    required this.maxY,
    required this.minY,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (spots.isEmpty) return;

    final range = maxY - minY;

    for (int i = 0; i < spots.length; i++) {
      final spot = spots[i];
      final value = values[i];

      // Calculate position
      final x = (spot.x / (spots.length - 1)) * size.width;
      final normalizedY = (spot.y - minY) / range;
      final y = size.height - (normalizedY * size.height);

      // Create TextPainter for this label
      final textSpan = TextSpan(
        text: '${value.round()}d',
        style: TextStyle(
          color: selectedIndex == i
              ? const Color(0xFFFF1493)
              : const Color(0xFFFF1493),
          fontSize: selectedIndex == i ? 13 : 11,
          fontWeight: selectedIndex == i ? FontWeight.bold : FontWeight.w600,
        ),
      );

      final textPainter = TextPainter(text: textSpan)
        ..textDirection = ui.TextDirection.ltr;

      textPainter.layout();

      // Position label above the point
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height - 12),
      );
    }
  }

  @override
  bool shouldRepaint(_CycleLengthLabelsPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedIndex != selectedIndex;
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
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PeriodLengthBarChart(values: values, labels: labels),
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
        .map(
          (value) =>
              (ui.lerpDouble(0, value, _controller.value) ?? value).toDouble(),
        )
        .cast<double>()
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
                final label = widget.labels
                    .elementAt(groupIndex)
                    .split('-')
                    .last;
                return BarTooltipItem(
                  "$label · ${rod.toY.toStringAsFixed(0)}d",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
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
                    colors: [HerCyclePalette.deep, HerCyclePalette.magenta],
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
                          colors: [color.withOpacity(0.9), color],
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
                        color: Color(0xFFD81B60),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
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
    _IntensityLevel(
      label: 'Light',
      note: 'Gentle days',
      color: HerCyclePalette.blush,
    ),
    _IntensityLevel(
      label: 'Medium',
      note: 'Steady',
      color: HerCyclePalette.magenta,
    ),
    _IntensityLevel(
      label: 'Heavy',
      note: 'Peak flow',
      color: HerCyclePalette.deep,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
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
      final animated = (ui.lerpDouble(0, entry.value, factor) ?? entry.value)
          .clamp(0.0, 1.0);
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
        // Frosted glass snapshot panel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    "Intensity snapshot",
                    style: TextStyle(
                      color: Color(0xFF7B5BA0),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "$latestIntensity%",
                    style: const TextStyle(
                      color: Color(0xFFD87CC8),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _intensityDescriptor(latestIntensity),
                    style: const TextStyle(
                      color: Color(0xFF7B5BA0),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _currentSummary,
                style: const TextStyle(color: Color(0xFF7B5BA0), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _phaseContext(),
                style: TextStyle(
                  color: const Color(0xFF7B5BA0).withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Intensity level tiles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(flex: 1, child: _IntensityLevelBadge(level: _legend[0])),
            const SizedBox(width: 8),
            Flexible(flex: 1, child: _IntensityLevelBadge(level: _legend[1])),
            const SizedBox(width: 8),
            Flexible(flex: 1, child: _IntensityLevelBadge(level: _legend[2])),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Gridline labels on the left
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 30,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'H',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF7B5BA0).withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'M',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF7B5BA0).withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'L',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF7B5BA0).withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 30),
                      child: LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            handleBuiltInTouches: true,
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBorderRadius: BorderRadius.circular(12),
                              tooltipPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              getTooltipColor: (_) =>
                                  HerCyclePalette.deep.withOpacity(0.92),
                              getTooltipItems: (spots) => spots
                                  .map(
                                    (spot) => LineTooltipItem(
                                      "${widget.labels.elementAt(spot.spotIndex).split('-').last}\n${(spot.y * 100).round()}% intensity",
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
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
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 0.5,
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: const Color(0xFF7B5BA0).withOpacity(0.2),
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              );
                            },
                            drawVerticalLine: false,
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              isStrokeCapRound: true,
                              barWidth: 3,
                              color: const Color(0xFFD87CC8),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFC4A8D8).withOpacity(0.4),
                                    const Color(0xFFD87CC8).withOpacity(0.3),
                                    const Color(0xFFE87AB8).withOpacity(0.15),
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  final isPeak = _peakIndices.contains(index);
                                  final isActive = index == _touchedIndex;

                                  // Calculate intensity-based color
                                  final intensity = spots[index].y;
                                  Color dotStrokeColor;
                                  if (intensity >= 0.67) {
                                    // Heavy - hot pink
                                    dotStrokeColor = const Color(0xFFE87AB8);
                                  } else if (intensity >= 0.34) {
                                    // Medium - purple
                                    dotStrokeColor = const Color(0xFFD87CC8);
                                  } else {
                                    // Light - light purple
                                    dotStrokeColor = const Color(0xFFC4A8D8);
                                  }

                                  return FlDotCirclePainter(
                                    radius: isActive ? 6 : (isPeak ? 5.5 : 4),
                                    color: isPeak
                                        ? const Color(0xFFE87AB8)
                                        : Colors.white,
                                    strokeWidth: isActive
                                        ? 2.5
                                        : (isPeak ? 0 : 2),
                                    strokeColor: dotStrokeColor,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Peak label
                    if (_peakIndices.isNotEmpty)
                      Positioned(
                        left:
                            40 +
                            ((_peakIndices.first / (spots.length - 1)) *
                                (MediaQuery.of(context).size.width - 80)),
                        top: 8,
                        child: const Column(
                          children: [
                            Text(
                              'Peak',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE87AB8),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(
                                Icons.arrow_drop_down,
                                size: 12,
                                color: Color(0xFFE87AB8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Month labels and intensity labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 0, height: 20),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Low',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7B5BA0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Intensity over time',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7B5BA0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'High',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF7B5BA0),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    _buildChartLegendItem(
                      indicator: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFC4A8D8),
                            width: 2,
                          ),
                        ),
                      ),
                      label: 'light',
                    ),
                    const SizedBox(width: 16),
                    _buildChartLegendItem(
                      indicator: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD87CC8),
                            width: 2,
                          ),
                        ),
                      ),
                      label: 'medium',
                    ),
                    const SizedBox(width: 16),
                    _buildChartLegendItem(
                      indicator: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE87AB8),
                        ),
                      ),
                      label: 'peak / heavy',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegendItem({
    required Widget indicator,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF7B5BA0),
            fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            level.color.withOpacity(0.15),
            Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: level.color.withOpacity(0.25),
            ),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: level.color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            level.label,
            style: const TextStyle(
              color: Color(0xFF7B5BA0),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            level.note,
            style: const TextStyle(
              color: Color(0xFF7B5BA0),
              fontSize: 9,
              fontWeight: FontWeight.w400,
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

  const CycleHealthCircle({super.key, required this.healthScore, this.onTap});

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
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
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
    final nextPrediction = _formatDate(
      prediction?['next_period_date'] ?? prediction?['next_period'],
    );
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
                  child: _ReportStat(label: 'Phase', value: _currentPhase()),
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
                border: Border.all(
                  color: HerCyclePalette.deep.withOpacity(0.3),
                ),
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
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 36,
                  ),
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
          style: const TextStyle(color: HerCyclePalette.magenta, fontSize: 12),
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
