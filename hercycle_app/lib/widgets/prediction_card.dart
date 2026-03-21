import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/hercycle_palette.dart';

class _PhaseMetadata {
  final String label;
  final String chanceMessage;
  final Color accentColor;

  const _PhaseMetadata({
    required this.label,
    required this.chanceMessage,
    required this.accentColor,
  });
}

const Map<String, _PhaseMetadata> _phaseMetadataMap = {
  'menstruation': _PhaseMetadata(
    label: 'Menstrual',
    chanceMessage: 'Your body is resetting',
    accentColor: HerCyclePalette.deep,
  ),
  'follicular': _PhaseMetadata(
    label: 'Follicular',
    chanceMessage: 'Energy slowly blooming',
    accentColor: HerCyclePalette.blush,
  ),
  'ovulation': _PhaseMetadata(
    label: 'Ovulation',
    chanceMessage: 'Feeling bright and social',
    accentColor: HerCyclePalette.magenta,
  ),
  'luteal': _PhaseMetadata(
    label: 'Luteal',
    chanceMessage: 'Gentle days ahead',
    accentColor: HerCyclePalette.deep,
  ),
  'tracking': _PhaseMetadata(
    label: 'Tracking',
    chanceMessage: 'Learning your rhythm',
    accentColor: HerCyclePalette.deep,
  ),
};

class PredictionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback? onRingTap;
  final VoidCallback? onSwipePrevious;
  final VoidCallback? onSwipeNext;
  final VoidCallback? onCardTap;

  const PredictionCard({
    super.key,
    required this.data,
    this.onRingTap,
    this.onSwipePrevious,
    this.onSwipeNext,
    this.onCardTap,
  });

  DateTime? _parseDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatFertileWindow(Object? fertileWindow) {
    if (fertileWindow is List && fertileWindow.length >= 2) {
      final formatter = DateFormat.MMMd();
      final start = _parseDate(fertileWindow[0]);
      final end = _parseDate(fertileWindow[1]);
      if (start != null && end != null) {
        return '${formatter.format(start)} – ${formatter.format(end)}';
      }
      return '${fertileWindow[0]} – ${fertileWindow[1]}';
    }
    return '—';
  }

  _PhaseMetadata _metadataForPhase(String? rawPhase) {
    final normalized = rawPhase?.trim().toLowerCase() ?? '';
    if (normalized.contains('menstru')) {
      return _phaseMetadataMap['menstruation']!;
    }
    if (normalized.contains('follic')) {
      return _phaseMetadataMap['follicular']!;
    }
    if (normalized.contains('ovulat')) {
      return _phaseMetadataMap['ovulation']!;
    }
    if (normalized.contains('lute')) {
      return _phaseMetadataMap['luteal']!;
    }
    return _phaseMetadataMap['tracking']!;
  }

  String _daysLeftLabel(DateTime? nextPeriod) {
    if (nextPeriod == null) return 'Days left: —';
    final now = DateTime.now();
    final diff = nextPeriod.difference(now).inDays;
    return diff < 0 ? 'Period today' : 'Days left: ${max(0, diff)}';
  }

  void _showMicroLabel(BuildContext context, String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(label),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Widget _buildChevronButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: HerCyclePalette.deep),
      ),
    );
  }

  Widget _floatingAction(
    BuildContext context,
    IconData icon,
    String microLabel,
  ) {
    return Positioned(
      left: icon == Icons.sunny ? 26 : null,
      right: icon == Icons.sunny ? null : 26,
      top: 130,
      child: GestureDetector(
        onTap: () => _showMicroLabel(context, microLabel),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.8),
                blurRadius: 20,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: HerCyclePalette.deep.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: HerCyclePalette.deep, size: 24),
        ),
      ),
    );
  }

  List<Color> _getCardBackgroundGradient(String phase) {
    final normalized = phase.toLowerCase();
    if (normalized.contains('menstru')) {
      return [
        const Color(0xFFFFDCE9), // Light bright pink
        const Color(0xFFFFC7E0), // Light magenta
      ];
    } else if (normalized.contains('follic')) {
      return [
        const Color(0xFFD4F5E3), // Light green
        const Color(0xFFFFF9C4), // Light yellow
      ];
    } else if (normalized.contains('ovulat')) {
      return [
        const Color(0xFFFFE0B2), // Light orange
        const Color(0xFFFFCDD2), // Light red
      ];
    } else if (normalized.contains('lute')) {
      return [
        const Color(0xFFBBDEFB), // Light blue
        const Color(0xFFE1BEE7), // Light purple
      ];
    }
    return [
      const Color(0xFFFFDCE9), // Default light pink
      const Color(0xFFFFC7E0), // Default light magenta
    ];
  }

  List<Color> _getPhaseGradientColors(String phase) {
    final normalized = phase.toLowerCase();
    if (normalized.contains('menstru')) {
      return [
        const Color(0xFFFF6B9D), // Bright pink
        const Color(0xFFE84B8A), // Magenta
      ];
    } else if (normalized.contains('follic')) {
      return [
        const Color(0xFF4ECB71), // Bright green
        const Color(0xFFFFC107), // Bright yellow
      ];
    } else if (normalized.contains('ovulat')) {
      return [
        const Color(0xFFFF9800), // Bright orange
        const Color(0xFFE74C3C), // Bright red
      ];
    } else if (normalized.contains('lute')) {
      return [
        const Color(0xFF2196F3), // Bright blue
        const Color(0xFF9C27B0), // Bright purple
      ];
    }
    return [
      const Color(0xFFFF6B9D), // Default bright pink
      const Color(0xFFE84B8A), // Default magenta
    ];
  }

  Color _getRingColor(String phase) {
    final normalized = phase.toLowerCase();
    if (normalized.contains('menstru')) {
      return const Color(0xFFFF6B9D); // Bright pink
    } else if (normalized.contains('follic')) {
      return const Color(0xFFFFC107); // Bright yellow
    } else if (normalized.contains('ovulat')) {
      return const Color(0xFFE74C3C); // Bright red
    } else if (normalized.contains('lute')) {
      return const Color(0xFF2196F3); // Bright blue
    }
    return const Color(0xFFFF6B9D); // Default bright pink
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? nextPeriod = _parseDate(data['predicted_next_period']);
    final DateTime referenceDate = nextPeriod ?? DateTime.now();
    final int cycleDay = int.tryParse(data['cycle_day']?.toString() ?? '') ?? 1;
    final int cycleLength =
        int.tryParse(data['cycle_length']?.toString() ?? '') ?? 28;
    final double progress = cycleLength > 0
        ? (cycleDay / cycleLength).clamp(0.0, 1.0)
        : 0.0;
    final double confidence =
        (double.tryParse(data['confidence']?.toString() ?? '') ?? 0.0).clamp(
          0.0,
          1.0,
        );
    final String currentPhaseRaw =
        data['current_phase']?.toString() ?? 'Tracking';
    final _PhaseMetadata phaseMetadata = _metadataForPhase(currentPhaseRaw);
    final String displayPhase = phaseMetadata.label;
    final String chanceMessage = phaseMetadata.chanceMessage;
    final Color accent = phaseMetadata.accentColor;
    final String daysLeft = _daysLeftLabel(nextPeriod);
    final String fertileText = _formatFertileWindow(data['fertile_window']);
    final String monthLabel = DateFormat('MMMM yyyy').format(referenceDate);
    final String cycleLengthLabel = 'Cycle $cycleLength days total';
    final bool isLuteal = displayPhase.toLowerCase() == 'luteal';
    final String moodHint =
        'Mood tip: 🌙 Gentle energy—focus on nourishing movement';
    final double moonRotation = (referenceDate.month % 12) / 12;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: _getCardBackgroundGradient(displayPhase),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0, 10),
                blurRadius: 24,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                offset: const Offset(0, -2),
                blurRadius: 12,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: HerCyclePalette.deep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cycle Day $cycleDay',
                          style: TextStyle(
                            fontSize: 13,
                            color: HerCyclePalette.deep.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 320,
                child: GestureDetector(
                  onTap: onRingTap,
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < 0) {
                      onSwipeNext?.call();
                    } else if (velocity > 0) {
                      onSwipePrevious?.call();
                    }
                  },
                  child: GestureDetector(
                    onTap: onCardTap ?? onRingTap,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedProgress, _) {
                        final double tickOpacity =
                            0.35 + (animatedProgress * 0.65);
                        return TweenAnimationBuilder<double>(
                          key: ValueKey<int>(cycleDay),
                          tween: Tween(begin: 1.03, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOut,
                          builder: (context, dayScale, __) {
                            return Transform.scale(
                              scale: dayScale,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(300, 300),
                                    painter: PhaseCirclePainter(
                                      progress: animatedProgress,
                                      highlightColor: _getRingColor(
                                        displayPhase,
                                      ),
                                      gradientColors: _getPhaseGradientColors(
                                        displayPhase,
                                      ),
                                      strokeWidth: 9,
                                      cycleLength: cycleLength,
                                      currentDay: cycleDay,
                                      tickOpacity: tickOpacity,
                                    ),
                                  ),
                                  Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: _getCardBackgroundGradient(
                                          displayPhase,
                                        ),
                                        stops: const [0.3, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.12,
                                          ),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 32,
                                          spreadRadius: 4,
                                          offset: const Offset(0, -4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Day $cycleDay',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: HerCyclePalette.deep,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          displayPhase.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: HerCyclePalette.deep
                                                .withValues(alpha: 0.85),
                                            letterSpacing: 1.6,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          chanceMessage,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: HerCyclePalette.deep
                                                .withValues(alpha: 0.8),
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          daysLeft,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: HerCyclePalette.magenta,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Phase: $displayPhase',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: HerCyclePalette.deep,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          cycleLengthLabel,
                          style: TextStyle(
                            color: HerCyclePalette.deep.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Confidence',
                          style: TextStyle(
                            fontSize: 12,
                            color: HerCyclePalette.deep,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: confidence),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeInOut,
                            builder: (context, value, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: HerCyclePalette.light
                                    .withValues(alpha: 0.4),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  HerCyclePalette.magenta,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(confidence * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_view_month,
                          size: 16,
                          color: HerCyclePalette.deep.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Fertile window: $fertileText',
                            style: TextStyle(
                              color: HerCyclePalette.deep.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isLuteal) ...[
                      const SizedBox(height: 8),
                      Text(
                        moodHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: HerCyclePalette.deep.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PhaseCirclePainter extends CustomPainter {
  final double progress;
  final Color highlightColor;
  final List<Color> gradientColors;
  final double strokeWidth;
  final int cycleLength;
  final int currentDay;
  final double tickOpacity;

  PhaseCirclePainter({
    required this.progress,
    required this.highlightColor,
    required this.gradientColors,
    this.strokeWidth = 10,
    this.cycleLength = 28,
    this.currentDay = 1,
    this.tickOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = min(size.width, size.height) / 2 - strokeWidth - 8;

    final Paint basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    // Create gradient shader for progress arc
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = ui.Gradient.sweep(
        center,
        gradientColors,
        [0.0, 1.0],
        TileMode.clamp,
        -pi / 2,
        -pi / 2 + (2 * pi * 0.3),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Paint tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35 + (0.3 * tickOpacity))
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius, basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    const double tickLength = 11;
    final int ticks = cycleLength;
    for (int i = 0; i < ticks; i++) {
      final double angle = (2 * pi / ticks) * i - pi / 2;
      final Offset start = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final Offset end = Offset(
        center.dx + (radius - tickLength) * cos(angle),
        center.dy + (radius - tickLength) * sin(angle),
      );
      canvas.drawLine(start, end, tickPaint);
    }

    final Paint innerShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - strokeWidth * 0.5, innerShadow);
    _drawDayNumbers(canvas, center, radius);
  }

  void _drawDayNumbers(Canvas canvas, Offset center, double radius) {
    final double labelRadius = radius + strokeWidth + 14;

    // Place each day label evenly around the dial using polar coordinates;
    // the labelRadius keeps them outside the progress arc.
    const Color highlightColor = Color(0xFF5B2D82);
    const Color regularColor = Color(0xFF7B4DB0);

    for (int day = 1; day <= cycleLength; day++) {
      final double angle = (2 * pi / cycleLength) * (day - 1) - pi / 2;
      final Offset position = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      final bool isCurrentDay = day == currentDay;
      final textStyle = TextStyle(
        fontSize: isCurrentDay ? 14 : 10,
        fontWeight: isCurrentDay ? FontWeight.w700 : FontWeight.w500,
        color: isCurrentDay
            ? highlightColor
            : regularColor.withValues(alpha: 0.6),
      );

      final textPainter = TextPainter(
        text: TextSpan(text: day.toString(), style: textStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      final Offset textOffset =
          position - Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant PhaseCirclePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.gradientColors != gradientColors ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.cycleLength != cycleLength ||
        oldDelegate.currentDay != currentDay ||
        oldDelegate.tickOpacity != tickOpacity;
  }
}
