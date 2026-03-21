import 'dart:math';
import 'package:flutter/material.dart';

enum FlowIntensity { none, light, medium, heavy }

enum MoodType { happy, calm, sad, anxious, irritable, tired }

enum EnergyLevel { low, medium, high }

class DailyLog {
  final DateTime date;
  final FlowIntensity flow;
  final MoodType? mood;
  final EnergyLevel? energy;
  final List<String> symptoms;

  DailyLog({
    required this.date,
    required this.flow,
    this.mood,
    this.energy,
    required this.symptoms,
  });
}

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

class DateRange {
  final int startDay;
  final int endDay;

  DateRange({required this.startDay, required this.endDay});
}

class CycleChartData {
  final int cycleLength;
  final int todayDay;
  final Map<String, DateRange> phases;
  final Map<String, List<double>> hormonePoints;
  final List<SymptomDot> symptomDots;

  CycleChartData({
    required this.cycleLength,
    required this.todayDay,
    required this.phases,
    required this.hormonePoints,
    required this.symptomDots,
  });
}

double _clamp(double value, double min, double max) {
  return value < min ? min : (value > max ? max : value);
}

CycleChartData computeCycleChart(List<DailyLog> logs, {int? overrideTodayDay}) {
  if (logs.isEmpty) {
    return _defaultCycleChartData();
  }

  final sortedLogs = List<DailyLog>.from(logs)
    ..sort((a, b) => a.date.compareTo(b.date));

  DateTime? cycleStartDate;
  for (final log in sortedLogs) {
    if (log.flow == FlowIntensity.light ||
        log.flow == FlowIntensity.medium ||
        log.flow == FlowIntensity.heavy) {
      cycleStartDate = log.date;
      break;
    }
  }

  // If no flow data found, use the oldest log date as cycle start
  if (cycleStartDate == null) {
    cycleStartDate = sortedLogs.isNotEmpty
        ? sortedLogs.first.date
        : DateTime.now();
  }

  final List<int> cycleLengths = [];
  DateTime currentStart = cycleStartDate;

  for (int i = 1; i < sortedLogs.length; i++) {
    final log = sortedLogs[i];
    final daysSinceStart = log.date.difference(currentStart).inDays;

    if (daysSinceStart >= 18 &&
        (log.flow == FlowIntensity.light ||
            log.flow == FlowIntensity.medium ||
            log.flow == FlowIntensity.heavy)) {
      cycleLengths.add(daysSinceStart);
      currentStart = log.date;
    }
  }

  int cycleLength = 28;
  if (cycleLengths.isNotEmpty) {
    cycleLength = (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length)
        .round();
  }

  final currentCycleStart = cycleStartDate;
  final currentCycleEnd = currentCycleStart.add(Duration(days: cycleLength));

  final currentCycleLogs = sortedLogs
      .where(
        (log) =>
            !log.date.isBefore(currentCycleStart) &&
            !log.date.isAfter(currentCycleEnd),
      )
      .toList();

  int menstruationEnd = 1;

  for (final log in currentCycleLogs) {
    final cycleDay = log.date.difference(currentCycleStart).inDays + 1;
    if (log.flow != FlowIntensity.none) {
      menstruationEnd = cycleDay;
    }
  }

  int ovulationDay = (cycleLength * 0.5).round();
  for (final log in currentCycleLogs) {
    if (log.symptoms.contains('discharge')) {
      ovulationDay = log.date.difference(currentCycleStart).inDays + 1;
      break;
    }
  }

  final follicularStart = menstruationEnd + 1;
  final follicularEnd = max(1, ovulationDay - 1);
  final lutealStart = ovulationDay + 1;
  final lutealEnd = cycleLength;

  final phases = {
    'menstruation': DateRange(startDay: 1, endDay: menstruationEnd),
    'follicular': DateRange(startDay: follicularStart, endDay: follicularEnd),
    'ovulation': DateRange(startDay: ovulationDay, endDay: ovulationDay),
    'luteal': DateRange(startDay: lutealStart, endDay: lutealEnd),
  };

  double g(double d, double mean, double sigma) =>
      exp(-0.5 * pow((d - mean) / sigma, 2));

  final oestradiol = <double>[];
  final progesterone = <double>[];
  final lh = <double>[];
  final fsh = <double>[];

  for (int d = 1; d <= cycleLength; d++) {
    final dDouble = d.toDouble();
    final ovulationDayDouble = ovulationDay.toDouble();
    final lutealStartDouble = lutealStart.toDouble();
    final follicularStartDouble = follicularStart.toDouble();

    final estradiolValue =
        g(dDouble, ovulationDayDouble, 2.5) +
        g(dDouble, lutealStartDouble + (lutealEnd - lutealStart) * 0.4, 4.0) *
            0.45;
    oestradiol.add(_clamp(estradiolValue, 0, 1));

    final progesteroneValue = d < ovulationDay
        ? 0.02
        : g(
            dDouble,
            lutealStartDouble + (lutealEnd - lutealStart) * 0.45,
            (lutealEnd - lutealStart) * 0.28,
          );
    progesterone.add(_clamp(progesteroneValue, 0, 1));

    final lhValue = g(dDouble, ovulationDayDouble, 1.2);
    lh.add(_clamp(lhValue, 0, 1));

    final fshValue =
        g(dDouble, follicularStartDouble + 3, 3.5) * 0.75 +
        g(dDouble, ovulationDayDouble, 1.5) * 0.5;
    fsh.add(_clamp(fshValue, 0, 1));
  }

  final todayDayRaw =
      overrideTodayDay ??
      DateTime.now().difference(currentCycleStart).inDays + 1;
  final todayDay = todayDayRaw.clamp(1, cycleLength);

  return CycleChartData(
    cycleLength: cycleLength,
    todayDay: todayDay,
    phases: phases,
    hormonePoints: {
      'oestradiol': oestradiol,
      'progesterone': progesterone,
      'lh': lh,
      'fsh': fsh,
    },
    symptomDots: [],
  );
}

CycleChartData _defaultCycleChartData() {
  const cycleLength = 28;
  const ovulationDay = 14;
  const menstruationEnd = 5;
  const lutealStart = 15;

  double g(double d, double mean, double sigma) =>
      exp(-0.5 * pow((d - mean) / sigma, 2));

  final oestradiol = <double>[];
  final progesterone = <double>[];
  final lh = <double>[];
  final fsh = <double>[];

  for (int d = 1; d <= cycleLength; d++) {
    final dDouble = d.toDouble();

    final estradiolValue =
        g(dDouble, ovulationDay.toDouble(), 2.5) +
        g(dDouble, lutealStart.toDouble() + 5.0, 4.0) * 0.45;
    oestradiol.add(_clamp(estradiolValue, 0, 1));

    final progesteroneValue = d < ovulationDay
        ? 0.02
        : g(dDouble, lutealStart.toDouble() + 5.0, 3.0);
    progesterone.add(_clamp(progesteroneValue, 0, 1));

    final lhValue = g(dDouble, ovulationDay.toDouble(), 1.2);
    lh.add(_clamp(lhValue, 0, 1));

    final fshValue =
        g(dDouble, 9.0, 3.5) * 0.75 +
        g(dDouble, ovulationDay.toDouble(), 1.5) * 0.5;
    fsh.add(_clamp(fshValue, 0, 1));
  }

  final today = DateTime.now();
  final dayInCycle = ((today.day - 1) % cycleLength) + 1;

  return CycleChartData(
    cycleLength: cycleLength,
    todayDay: dayInCycle,
    phases: {
      'menstruation': DateRange(startDay: 1, endDay: menstruationEnd),
      'follicular': DateRange(
        startDay: menstruationEnd + 1,
        endDay: ovulationDay - 1,
      ),
      'ovulation': DateRange(startDay: ovulationDay, endDay: ovulationDay),
      'luteal': DateRange(startDay: lutealStart, endDay: cycleLength),
    },
    hormonePoints: {
      'oestradiol': oestradiol,
      'progesterone': progesterone,
      'lh': lh,
      'fsh': fsh,
    },
    symptomDots: [],
  );
}

class CycleChartPainter extends CustomPainter {
  final CycleChartData data;

  CycleChartPainter(this.data);

  static const double _leftPadding = 40;
  static const double _rightPadding = 20;
  static const double _topPadding = 32;
  static const double _bottomPadding = 44;
  static const double _axisLabelWidth = 25;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftPadding - _rightPadding;
    final chartHeight = size.height - _topPadding - _bottomPadding;

    // Draw background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw in order: backgrounds, then axes, then curves, then indicators
    _drawPhaseBands(canvas, size, chartWidth, chartHeight);
    _drawPhaseHeaders(canvas, size, chartWidth, chartHeight);
    _drawAxisLabels(canvas, size, chartHeight);
    _drawHorizontalGridlines(canvas, size, chartWidth, chartHeight);
    _drawVerticalAxisLine(canvas, size, chartHeight);
    _drawHormoneCurves(canvas, size, chartWidth, chartHeight);
    _drawSymptomDots(canvas, size, chartWidth, chartHeight);
    _drawTodayIndicator(canvas, size, chartWidth, chartHeight);
    _drawDayMarkers(canvas, size, chartWidth, chartHeight);
  }

  double _dayToX(double day, double chartWidth) {
    return _leftPadding + (day - 1) / max(1, data.cycleLength - 1) * chartWidth;
  }

  double _valueToY(double value, double chartHeight) {
    return _topPadding + chartHeight * (1 - value);
  }

  void _drawPhaseBands(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final phaseColors = {
      'menstruation': Color(0xFFFFCCE0),
      'follicular': Color(0xFFC8F0C8),
      'ovulation': Color(0xFFDDD0FF),
      'luteal': Color(0xFFC8DCF8),
    };

    for (final entry in data.phases.entries) {
      final phaseName = entry.key;
      final range = entry.value;
      final color = phaseColors[phaseName]!.withOpacity(0.15);

      final startX = _dayToX(range.startDay.toDouble(), chartWidth);
      final endX = _dayToX(range.endDay.toDouble() + 1, chartWidth);

      canvas.drawRect(
        Rect.fromLTRB(startX, _topPadding, endX, _topPadding + chartHeight),
        Paint()..color = color,
      );
    }
  }

  void _drawPhaseHeaders(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final phaseColors = {
      'menstruation': Color(0xFFFFCCE0),
      'follicular': Color(0xFFC8F0C8),
      'ovulation': Color(0xFFDDD0FF),
      'luteal': Color(0xFFC8DCF8),
    };

    final phaseDarkColors = {
      'menstruation': Color(0xFFCC8EB0),
      'follicular': Color(0xFF90C890),
      'ovulation': Color(0xFFB8A8E8),
      'luteal': Color(0xFF90B8E0),
    };

    final phaseDisplayNames = {
      'menstruation': 'Menstruation',
      'follicular': 'Follicular',
      'ovulation': 'Ovulation',
      'luteal': 'Luteal',
    };

    final labelCenterY = _topPadding + 12;

    for (final entry in data.phases.entries) {
      final phaseName = entry.key;
      final range = entry.value;
      final color = phaseColors[phaseName]!;
      final darkColor = phaseDarkColors[phaseName]!;

      final startX = _dayToX(range.startDay.toDouble(), chartWidth);
      final endX = _dayToX(range.endDay.toDouble() + 1, chartWidth);
      final width = max(1.0, endX - startX);

      // Always show full phase name
      final displayName = phaseDisplayNames[phaseName] ?? phaseName;

      final textPainter = TextPainter(
        text: TextSpan(
          text: displayName,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: darkColor,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      textPainter.layout();

      // Center text in the band horizontally
      final bandCenterX = startX + width / 2;
      final textX = bandCenterX - (textPainter.width / 2);
      final textY = labelCenterY - (textPainter.height / 2);

      // Draw label text without clipping - allow full visibility
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  void _drawVerticalAxisLine(Canvas canvas, Size size, double chartHeight) {
    // Draw vertical axis line on the left
    canvas.drawLine(
      Offset(_leftPadding - 2, _topPadding),
      Offset(_leftPadding - 2, _topPadding + chartHeight),
      Paint()
        ..color = Color(0xFFD0B0E0)
        ..strokeWidth = 1.0,
    );
  }

  void _drawHorizontalGridlines(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final paint = Paint()
      ..color = Color(0xFFE0C8F0)
      ..strokeWidth = 0.6;

    // Draw gridlines at H (top), M (middle), L (bottom) positions
    for (double ratio in [0.0, 0.5, 1.0]) {
      final y = _topPadding + chartHeight * ratio;
      _drawDashedLine(
        canvas,
        Offset(_leftPadding, y),
        Offset(_leftPadding + chartWidth, y),
        paint,
        3.0,
        2.5,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashWidth,
    double dashGap,
  ) {
    final distance = (end - start).distance;
    final direction = (end - start).direction;

    for (double i = 0; i < distance; i += dashWidth + dashGap) {
      final p1 = start + Offset.fromDirection(direction, i);
      final p2 =
          start + Offset.fromDirection(direction, min(i + dashWidth, distance));
      canvas.drawLine(p1, p2, paint);
    }
  }

  void _drawAxisLabels(Canvas canvas, Size size, double chartHeight) {
    // Draw H, M, L labels on the left axis
    final labels = [
      {'label': 'H', 'ratio': 0.0},
      {'label': 'M', 'ratio': 0.5},
      {'label': 'L', 'ratio': 1.0},
    ];

    final labelPaint = TextPainter(textDirection: TextDirection.ltr);

    for (final item in labels) {
      final label = item['label'] as String;
      final ratio = item['ratio'] as double;
      final y = _topPadding + chartHeight * ratio;

      labelPaint.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Color(0xFF9B7BAB),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      labelPaint.layout();

      // Center the label vertically on the gridline
      labelPaint.paint(
        canvas,
        Offset(_leftPadding - _axisLabelWidth + 5, y - labelPaint.height / 2),
      );
    }
  }

  void _drawHormoneCurves(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    // Draw hormone curves with smooth rendering
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['oestradiol']!,
      Color(0xFFE870C0),
      2.5,
      chartWidth,
      chartHeight,
      fill: true,
      fillOpacity: 0.10,
    );
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['progesterone']!,
      Color(0xFF7058D8),
      2.5,
      chartWidth,
      chartHeight,
      fill: true,
      fillOpacity: 0.10,
    );
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['lh']!,
      Color(0xFF58C870),
      2.0,
      chartWidth,
      chartHeight,
    );
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['fsh']!,
      Color(0xFFF0A050),
      2.0,
      chartWidth,
      chartHeight,
    );
  }

  void _drawCurveWithFill(
    Canvas canvas,
    List<double> points,
    Color color,
    double strokeWidth,
    double chartWidth,
    double chartHeight, {
    bool fill = false,
    double fillOpacity = 0.12,
  }) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Use quadratic bezier curves for smooth paths
    final path = Path();
    path.moveTo(_dayToX(1, chartWidth), _valueToY(points[0], chartHeight));

    for (int i = 1; i < points.length; i++) {
      final x1 = _dayToX(i.toDouble(), chartWidth);
      final y1 = _valueToY(points[i - 1], chartHeight);
      final x2 = _dayToX(i + 1.0, chartWidth);
      final y2 = _valueToY(points[i], chartHeight);

      // Use quadratic bezier for smooth curves
      path.quadraticBezierTo(x1, y1, (x1 + x2) / 2, (y1 + y2) / 2);
    }

    canvas.drawPath(path, paint);

    // Draw fill under curve if requested
    if (fill) {
      final fillPath = Path();
      fillPath.moveTo(
        _dayToX(1, chartWidth),
        _valueToY(points[0], chartHeight),
      );

      for (int i = 1; i < points.length; i++) {
        final x1 = _dayToX(i.toDouble(), chartWidth);
        final y1 = _valueToY(points[i - 1], chartHeight);
        final x2 = _dayToX(i + 1.0, chartWidth);
        final y2 = _valueToY(points[i], chartHeight);

        fillPath.quadraticBezierTo(x1, y1, (x1 + x2) / 2, (y1 + y2) / 2);
      }

      fillPath.lineTo(
        _dayToX(points.length.toDouble(), chartWidth),
        _valueToY(0, chartHeight),
      );
      fillPath.lineTo(_dayToX(1, chartWidth), _valueToY(0, chartHeight));
      fillPath.close();

      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color.withOpacity(fillOpacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawTodayIndicator(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final x = _dayToX(data.todayDay.toDouble(), chartWidth);

    // Draw vertical dashed line from chartTop to chartBottom first
    final linePaint = Paint()
      ..color = Color(0xFFC87BE8)
      ..strokeWidth = 1.2;

    _drawDashedLine(
      canvas,
      Offset(x, _topPadding),
      Offset(x, _topPadding + chartHeight),
      linePaint,
      3.5,
      2.5,
    );

    // Draw pill badge above chart
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Day ${data.todayDay}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const badgeHorizontalPadding = 8.0;
    const badgeHeight = 18.0;
    const badgeBorderRadius = 9.0;
    final badgeWidth = textPainter.width + (badgeHorizontalPadding * 2);
    final badgeX = x - badgeWidth / 2;
    final badgeY =
        _topPadding - 16.0; // Pill sits flush above chart panel top edge

    // Draw pill: RRect with #C87BE8 fill, height 18px, borderRadius 9
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeWidth, badgeHeight),
        const Radius.circular(badgeBorderRadius),
      ),
      Paint()..color = Color(0xFFC87BE8),
    );

    // Draw white text "Day X" centered inside pill
    textPainter.paint(
      canvas,
      Offset(
        x - textPainter.width / 2,
        badgeY + (badgeHeight - textPainter.height) / 2,
      ),
    );
  }

  void _drawSymptomDots(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    // Draw symptom dots on the chart at the day they were logged
    const dotRadius = 4.0;
    final dotsY =
        _topPadding + chartHeight * 0.75; // Position at 75% height of chart

    for (final dot in data.symptomDots) {
      final x = _dayToX(dot.cycleDay.toDouble(), chartWidth);

      // Draw dot with subtle shadow effect
      canvas.drawCircle(
        Offset(x, dotsY),
        dotRadius,
        Paint()
          ..color = dot.color
          ..style = PaintingStyle.fill,
      );

      // Draw slight border for definition
      canvas.drawCircle(
        Offset(x, dotsY),
        dotRadius,
        Paint()
          ..color = dot.color.withOpacity(0.5)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawDayMarkers(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    // Show markers for key days: 1, 7, 14, 21, 28 (only if cycle length allows)
    final markerDays = [
      1,
      7,
      14,
      21,
      28,
    ].where((d) => d <= data.cycleLength).toList();

    final tickY = _topPadding + chartHeight + 3;
    final labelY = _topPadding + chartHeight + 16;

    for (final day in markerDays) {
      final x = _dayToX(day.toDouble(), chartWidth);

      // Draw tick mark
      canvas.drawLine(
        Offset(x, tickY),
        Offset(x, tickY + 7),
        Paint()
          ..color = Color(0xFFBBA0CF)
          ..strokeWidth = 1.0,
      );

      // Draw day label
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Day $day',
          style: TextStyle(
            color: Color(0xFF8B6BA3),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(x - textPainter.width / 2, labelY));
    }
  }

  @override
  bool shouldRepaint(CycleChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class MenstrualCycleChartCard extends StatelessWidget {
  final List<DailyLog> logs;
  final int? overrideTodayDay;

  const MenstrualCycleChartCard({
    Key? key,
    required this.logs,
    this.overrideTodayDay,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = computeCycleChart(logs, overrideTodayDay: overrideTodayDay);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE8F5), Color(0xFFF0E8FF), Color(0xFFE8F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFC87BE8).withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Color(0xFFC87BE8).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFFC87BE8).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: EdgeInsets.all(20),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE870B8).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFC87BE8).withOpacity(0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(0xFFC87BE8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'The menstrual cycle',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7B3FA0),
                              ),
                            ),
                            Text(
                              'Track your cycle phases and hormones',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9050A0),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Day 1–${data.cycleLength}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7B3FA0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                alignment: WrapAlignment.center,
                children: [
                  _LegendItem('Oestradiol', Color(0xFFE870C0)),
                  _LegendItem('Progesterone', Color(0xFF7058D8)),
                  _LegendItem('LH', Color(0xFF58C870)),
                  _LegendItem('FSH', Color(0xFFF0A050)),
                ],
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.fromLTRB(0, 10, 0, 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 800,
                      height: 220,
                      child: CustomPaint(
                        painter: CycleChartPainter(data),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _phaseCard(
                          'Menstruation',
                          '↓ Work capacity · ↑ Pain',
                          Color(0xFFFFCCE0),
                          Color(0xFFB04070),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _phaseCard(
                          'Follicular',
                          '↑ Work capacity · ↑ Strength',
                          Color(0xFFC8F0C8),
                          Color(0xFF2A7040),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _phaseCard(
                          'Ovulation',
                          '↑ ACL risk · Peak energy',
                          Color(0xFFE0D0FF),
                          Color(0xFF6030A0),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _phaseCard(
                          'Luteal',
                          '↑ Fatigue · ↓ Mood',
                          Color(0xFFC8DCFF),
                          Color(0xFF204080),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _phaseCard(
    String title,
    String insight,
    Color bgColor,
    Color textColor,
  ) {
    // Use stronger background colors with appropriate opacity
    Color strongerBgColor;
    switch (title) {
      case 'Menstruation':
        strongerBgColor = Color(0xFFFFCCE0);
        break;
      case 'Follicular':
        strongerBgColor = Color(0xFFC8F0C8);
        break;
      case 'Ovulation':
        strongerBgColor = Color(0xFFE0D0FF);
        break;
      case 'Luteal':
        strongerBgColor = Color(0xFFC8DCFF);
        break;
      default:
        strongerBgColor = bgColor;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: strongerBgColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: strongerBgColor.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFC87BE8).withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 4),
          Text(
            insight,
            style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.2),
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF9050A0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
