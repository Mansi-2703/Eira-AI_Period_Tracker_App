import 'dart:math';

import 'package:flutter/material.dart';

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
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return HealthReportSheet(
          confidence: _confidence,
          stability: _stability,
          risk: _risk,
          cycles: _recentCycles,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final labeledCycles = _recentCycles;
    final cycleValues = labeledCycles.map((e) => e.cycleLength).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChartCard(
          title: "Cycle length history",
          subtitle: "Tracked cycles",
          child: SizedBox(
            height: 180,
            child: BarChartPainterWidget(
              values: cycleValues,
              labels: labeledCycles.map((e) => e.label).toList(),
              color: Colors.pinkAccent,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: "Cycle length trend",
          subtitle: "Normal range band 21–35 days",
          child: SizedBox(
            height: 200,
            child: ReferenceLineChart(
              values: cycleValues,
              labels: labeledCycles.map((e) => e.label).toList(),
              color: Colors.deepPurpleAccent,
              lowerBound: 21,
              upperBound: 35,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ChartCard(
          title: "Cycle health analysis",
          subtitle: "Based on predictions + quiz",
          child: GestureDetector(
            onTap: () => _openHealthReport(context),
            child: SizedBox(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${(_healthScore * 100).round()}%",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _healthScore >= 0.6
                          ? "Steady & balanced cycles"
                          : "Observe for irregularities",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _healthScore.clamp(0.0, 1.0),
                      color: Colors.pinkAccent,
                      backgroundColor: Colors.pink.shade50,
                    ),
                  ],
                ),
              ),
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

  const ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.pinkAccent,
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class BarChartPainterWidget extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;

  const BarChartPainterWidget({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(values: values, color: color),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: labels
              .map(
                (label) => Text(
                  label.isEmpty ? '-' : label.split('-').last,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _BarChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final maxVal = values.reduce(max);
    final barWidth = size.width / (values.length * 1.5);
    final paint = Paint()..color = color.withOpacity(0.8);
    for (var i = 0; i < values.length; i++) {
      final height = (values[i] / (maxVal == 0 ? 1 : maxVal)) * size.height;
      final x = i * barWidth * 1.3 + barWidth / 2;
      final rect = Rect.fromLTWH(x, size.height - height, barWidth, height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class ReferenceLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color color;
  final double lowerBound;
  final double upperBound;

  const ReferenceLineChart({
    super.key,
    required this.values,
    required this.labels,
    required this.color,
    required this.lowerBound,
    required this.upperBound,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReferenceLinePainter(
        values: values,
        color: color,
        lower: lowerBound,
        upper: upperBound,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: labels
              .map(
                (label) => Text(
                  label.isEmpty ? '-' : label.split('-').last,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _ReferenceLinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double lower;
  final double upper;

  _ReferenceLinePainter({
    required this.values,
    required this.color,
    required this.lower,
    required this.upper,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxVal = values.reduce(max);
    final minVal = values.reduce(min);
    final range = maxVal - minVal == 0 ? 1 : maxVal - minVal;
    final lowerNorm = (lower - minVal) / range;
    final upperNorm = (upper - minVal) / range;

    final bandPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final bandTop = size.height - upperNorm * size.height;
    final bandHeight = (upperNorm - lowerNorm) * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, bandTop, size.width, bandHeight.clamp(0, size.height)),
      bandPaint,
    );

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final normalized = (values[i] - minVal) / range;
      final y = size.height - normalized * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ReferenceLinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lower != lower ||
        oldDelegate.upper != upper;
  }
}

class HealthReportSheet extends StatelessWidget {
  final double confidence;
  final double stability;
  final double risk;
  final List<_LabeledCycle> cycles;

  const HealthReportSheet({
    super.key,
    required this.confidence,
    required this.stability,
    required this.risk,
    required this.cycles,
  });

  @override
  Widget build(BuildContext context) {
    final averageCycle = cycles.isEmpty
        ? 0.0
        : cycles.map((e) => e.cycleLength).reduce((a, b) => a + b) /
              cycles.length;
    final averagePeriod = cycles.isEmpty
        ? 0.0
        : cycles.map((e) => e.periodLength).reduce((a, b) => a + b) /
              cycles.length;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Cycle Health Report",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ReportStat(
                label: "Avg. cycle",
                value: "${averageCycle.round()}d",
              ),
              _ReportStat(
                label: "Period length",
                value: "${averagePeriod.round()}d",
              ),
              _ReportStat(
                label: "Confidence",
                value: "${(confidence * 100).round()}%",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Stability & symptoms"),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: stability.clamp(0.0, 1.0),
                color: Colors.pinkAccent,
                backgroundColor: Colors.pink.shade50,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 1 - risk.clamp(0.0, 1.0),
                color: Colors.green,
                backgroundColor: Colors.green.shade50,
                minHeight: 8,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Trends based on your logged cycles and the quiz insights. Keep tracking to keep this score meaningful.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
        ],
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
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
