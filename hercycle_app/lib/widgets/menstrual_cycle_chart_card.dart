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
    cycleStartDate = sortedLogs.isNotEmpty ? sortedLogs.first.date : DateTime.now();
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

  final symptomDots = <SymptomDot>[];

  final moodColors = {
    MoodType.happy: Color(0xFF58C878),
    MoodType.calm: Color(0xFF7098E8),
    MoodType.anxious: Color(0xFFE8A840),
    MoodType.irritable: Color(0xFFE87070),
    MoodType.sad: Color(0xFFA878E8),
    MoodType.tired: Color(0xFFE870B8),
  };

  for (final log in currentCycleLogs) {
    final cycleDay = log.date.difference(currentCycleStart).inDays + 1;

    if (log.mood != null) {
      symptomDots.add(
        SymptomDot(
          cycleDay: cycleDay,
          type: 'mood',
          label: log.mood!.name,
          color: moodColors[log.mood]!,
        ),
      );
    }

    for (final symptom in log.symptoms) {
      symptomDots.add(
        SymptomDot(
          cycleDay: cycleDay,
          type: 'symptom',
          label: symptom,
          color: Color(0xFFE870B8),
        ),
      );
    }
  }

  final todayDayRaw = overrideTodayDay ?? DateTime.now().difference(currentCycleStart).inDays + 1;
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
    symptomDots: symptomDots,
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
        g(dDouble, 9.0, 3.5) * 0.75 + g(dDouble, ovulationDay.toDouble(), 1.5) * 0.5;
    fsh.add(_clamp(fshValue, 0, 1));
  }

  final today = DateTime.now();
  final dayInCycle = ((today.day - 1) % cycleLength) + 1;

  return CycleChartData(
    cycleLength: cycleLength,
    todayDay: dayInCycle,
    phases: {
      'menstruation': DateRange(startDay: 1, endDay: menstruationEnd),
      'follicular': DateRange(startDay: menstruationEnd + 1, endDay: ovulationDay - 1),
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

  static const double _leftPadding = 60;
  static const double _rightPadding = 40;
  static const double _topPadding = 40;
  static const double _bottomPadding = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final chartWidth = size.width - _leftPadding - _rightPadding;
    final chartHeight = size.height - _topPadding - _bottomPadding;

    _drawPhaseBands(canvas, size, chartWidth, chartHeight);
    _drawGridlines(canvas, size, chartWidth, chartHeight);
    _drawAxisLabels(canvas, size, chartHeight);
    _drawHormoneCurves(canvas, size, chartWidth, chartHeight);
    _drawTodayLine(canvas, size, chartWidth, chartHeight);
    _drawSymptomDots(canvas, size, chartWidth, chartHeight);
    _drawXAxisLabels(canvas, size, chartWidth, chartHeight);
    _drawPhaseDividers(canvas, size, chartHeight);
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

    final phaseDarkColors = {
      'menstruation': Color(0xFFCC8EB0),
      'follicular': Color(0xFF90C890),
      'ovulation': Color(0xFFB8A8E8),
      'luteal': Color(0xFF90B8E0),
    };

    for (final entry in data.phases.entries) {
      final phaseName = entry.key;
      final range = entry.value;
      final color = phaseColors[phaseName]!.withOpacity(0.18);

      final startX = _dayToX(range.startDay.toDouble(), chartWidth);
      final endX = _dayToX(range.endDay.toDouble() + 1, chartWidth);

      canvas.drawRect(
        Rect.fromLTRB(startX, _topPadding, endX, _topPadding + chartHeight),
        Paint()..color = color,
      );

      final phaseDisplayName =
          phaseName[0].toUpperCase() + phaseName.substring(1);
      final textPainter = TextPainter(
        text: TextSpan(
          text: phaseDisplayName,
          style: TextStyle(
            color: phaseDarkColors[phaseName],
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(startX + 4, _topPadding + 2));
    }
  }

  void _drawGridlines(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final paint = Paint()
      ..color = Color(0xFFC8A8D8)
      ..strokeWidth = 0.8;

    for (double ratio in [0.25, 0.5, 0.75]) {
      final y = _topPadding + chartHeight * ratio;
      _drawDashedLine(
        canvas,
        Offset(_leftPadding, y),
        Offset(_leftPadding + chartWidth, y),
        paint,
        4.0,
        3.0,
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
    final labels = ['H', 'M', 'L'];

    for (int i = 0; i < labels.length; i++) {
      final y = _topPadding + chartHeight * (1 - (i + 1) / 4);
      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(color: Color(0xFFC8A8D8), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(_leftPadding - 20, y - 4));
    }
  }

  void _drawHormoneCurves(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['oestradiol']!,
      Color(0xFFE870C0),
      3.5,
      chartWidth,
      chartHeight,
      fill: true,
    );
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['progesterone']!,
      Color(0xFF7058D8),
      3.5,
      chartWidth,
      chartHeight,
      fill: true,
    );
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['lh']!,
      Color(0xFF58C870),
      2.8,
      chartWidth,
      chartHeight,
    );
    _drawCurveWithFill(
      canvas,
      data.hormonePoints['fsh']!,
      Color(0xFFF0A050),
      2.8,
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
  }) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(_dayToX(1, chartWidth), _valueToY(points[0], chartHeight));

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        _dayToX(i + 1.0, chartWidth),
        _valueToY(points[i], chartHeight),
      );
    }

    canvas.drawPath(path, paint);

    if (fill) {
      final fillPath = Path()
        ..moveTo(_dayToX(1, chartWidth), _valueToY(points[0], chartHeight));
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(
          _dayToX(i + 1.0, chartWidth),
          _valueToY(points[i], chartHeight),
        );
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
          ..color = color.withOpacity(0.12)
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _drawTodayLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final x = _dayToX(data.todayDay.toDouble(), chartWidth);

    final paint = Paint()
      ..color = Color(0xFFC87BE8)
      ..strokeWidth = 1.5;

    _drawDashedLine(
      canvas,
      Offset(x, _topPadding),
      Offset(x, _topPadding + chartHeight),
      paint,
      4.0,
      3.0,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Day ${data.todayDay}',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final pillWidth = textPainter.width + 8;
    final pillHeight = textPainter.height + 4;
    final pillX = x - pillWidth / 2;
    const pillY = 2.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(pillX, pillY, pillWidth, pillHeight),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFFC87BE8),
    );

    textPainter.paint(canvas, Offset(pillX + 4, pillY + 2));
  }

  void _drawSymptomDots(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    const dotRadius = 4.0;
    final dotsY = _topPadding + chartHeight * 0.85;

    for (final dot in data.symptomDots) {
      final x = _dayToX(dot.cycleDay.toDouble(), chartWidth);

      canvas.drawCircle(
        Offset(x, dotsY),
        dotRadius,
        Paint()..color = dot.color,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: dot.label,
          style: TextStyle(color: dot.color, fontSize: 7.5),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + 6, dotsY - 4));
    }
  }

  void _drawXAxisLabels(
    Canvas canvas,
    Size size,
    double chartWidth,
    double chartHeight,
  ) {
    final days = [1, 5, 7, 14, 21, 28];
    final displayDays = days.where((d) => d <= data.cycleLength).toList();

    for (final day in displayDays) {
      final x = _dayToX(day.toDouble(), chartWidth);
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'Day $day',
          style: TextStyle(color: Color(0xFFC0A0D0), fontSize: 8),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, _topPadding + chartHeight + 8),
      );
    }
  }

  void _drawPhaseDividers(Canvas canvas, Size size, double chartHeight) {
    final dividerDays = [
      data.phases['follicular']!.startDay,
      data.phases['ovulation']!.startDay,
      data.phases['luteal']!.startDay,
    ];

    final paint = Paint()
      ..color = Color.fromARGB(77, 180, 140, 210)
      ..strokeWidth = 0.8;

    final chartWidth = size.width - _leftPadding - _rightPadding;

    for (final day in dividerDays) {
      final x = _dayToX(day.toDouble(), chartWidth);
      _drawDashedLine(
        canvas,
        Offset(x, _topPadding),
        Offset(x, _topPadding + chartHeight),
        paint,
        3.0,
        2.0,
      );
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFE8F5), Color(0xFFF0E8FF), Color(0xFFE8F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
              Row(
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
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _LegendItem('Oestradiol', Color(0xFFE870C0)),
                    SizedBox(width: 8),
                    _LegendItem('Progesterone', Color(0xFF7058D8)),
                    SizedBox(width: 8),
                    _LegendItem('LH', Color(0xFF58C870)),
                    SizedBox(width: 8),
                    _LegendItem('FSH', Color(0xFFF0A050)),
                  ],
                ),
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  height: 380,
                  child: InteractiveViewer(
                    boundaryMargin: EdgeInsets.all(20),
                    minScale: 0.8,
                    maxScale: 3.0,
                    child: SizedBox(
                      width: 1200,
                      height: 420,
                      child: CustomPaint(
                        painter: CycleChartPainter(data),
                        size: Size(1200, 420),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _PhaseInsightCard(
                    title: 'Menstruation',
                    insight: '↓ Work capacity · ↑ Pain',
                    backgroundColor: Color(0xFFFFCCE0),
                  ),
                  _PhaseInsightCard(
                    title: 'Follicular',
                    insight: '↑ Work capacity · ↑ Strength',
                    backgroundColor: Color(0xFFC8F0C8),
                  ),
                  _PhaseInsightCard(
                    title: 'Ovulation',
                    insight: '↑ ACL risk · Peak energy',
                    backgroundColor: Color(0xFFDDD0FF),
                  ),
                  _PhaseInsightCard(
                    title: 'Luteal',
                    insight: '↑ Fatigue · ↓ Mood',
                    backgroundColor: Color(0xFFC8DCF8),
                  ),
                ],
              ),
            ],
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
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9050A0),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseInsightCard extends StatelessWidget {
  final String title;
  final String insight;
  final Color backgroundColor;

  const _PhaseInsightCard({
    required this.title,
    required this.insight,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7B3FA0),
            ),
          ),
          SizedBox(height: 4),
          Text(
            insight,
            style: TextStyle(fontSize: 10, color: Color(0xFF9050A0)),
          ),
        ],
      ),
    );
  }
}
