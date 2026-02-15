import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/hercycle_palette.dart';

class CalendarPreview extends StatelessWidget {
  final DateTime month;
  final Set<String> predictedDates;
  final Set<String> loggedDates;
  final int? cycleLength;
  final int? periodLength;
  final VoidCallback onTap;
  final DateTime? nextPeriod;

  const CalendarPreview({
    super.key,
    required this.month,
    required this.predictedDates,
    required this.loggedDates,
    required this.onTap,
    this.cycleLength,
    this.periodLength,
    this.nextPeriod,
  });

  String _dateKey(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  DateTime _startOfCustomWeek(DateTime reference) {
    const weekStart = 6; // Saturday
    int diff = reference.weekday - weekStart;
    if (diff < 0) diff += 7;
    return reference.subtract(Duration(days: diff));
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? nextPeriodValue = nextPeriod;
    final DateTime referenceDate = nextPeriodValue ?? DateTime.now();
    final DateTime weekStart = _startOfCustomWeek(referenceDate);
    final List<DateTime> weekDates = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    final monthLabel = DateFormat('MMMM yyyy').format(month);
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onTap,
                  icon: Icon(Icons.chevron_left, color: HerCyclePalette.deep),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HerCyclePalette.deep,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: Icon(Icons.chevron_right, color: HerCyclePalette.deep),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: weekDates.map((day) {
                final key = _dateKey(day);
                final isSelected = DateUtils.isSameDay(day, referenceDate);
                final isToday = DateUtils.isSameDay(day, DateTime.now());
                final isPredicted = predictedDates.contains(key);
                final isLogged = loggedDates.contains(key);
                final backgroundColor = isSelected
                    ? HerCyclePalette.magenta
                    : isPredicted
                    ? HerCyclePalette.blush.withOpacity(0.4)
                    : Colors.transparent;
                final textColor = isSelected || isPredicted
                    ? Colors.white
                    : HerCyclePalette.deep;

                return Expanded(
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(day),
                        style: TextStyle(
                          fontSize: 12,
                          color: HerCyclePalette.deep.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: isToday
                              ? Border.all(
                                  color: HerCyclePalette.magenta,
                                  width: 2,
                                )
                              : Border.all(
                                  color: Colors.grey.withOpacity(0.35),
                                ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day.day.toString().padLeft(2, '0'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isLogged)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: colors.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, color: HerCyclePalette.deep, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cycle: ${cycleLength ?? '—'}d • Period: ${periodLength ?? '—'}d',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            if (nextPeriodValue != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: HerCyclePalette.magenta,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next period: ${DateFormat.yMMMMd().format(nextPeriodValue)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Tap to open the full calendar',
              style: TextStyle(
                color: HerCyclePalette.deep.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
