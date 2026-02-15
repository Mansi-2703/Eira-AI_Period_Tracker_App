import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';
import '../widgets/prediction_card.dart';
import '../widgets/calendar_preview.dart';
import '../widgets/prediction_charts.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? prediction;
  bool predictionLoading = true;
  List<dynamic> cycles = [];
  bool quizLoading = true;
  bool quizCompleted = false;
  Map<String, dynamic>? quizData;
  String? _cachedUsername;
  String? _cachedEmail;

  @override
  void initState() {
    super.initState();
    loadPrediction();
    loadCycles();
    loadQuizStatus();
    _loadCachedUserInfo();
  }

  Future<void> loadPrediction() async {
    final result = await ApiService.getPrediction();
    if (!mounted) return;
    setState(() {
      prediction = result;
      predictionLoading = false;
    });
  }

  Future<void> loadCycles() async {
    final result = await ApiService.fetchCycles();
    if (!mounted) return;
    setState(() {
      cycles = result;
    });
  }

  Future<void> loadQuizStatus() async {
    final status = await ApiService.fetchQuizProfile();
    if (!mounted) return;
    setState(() {
      quizCompleted = status?["completed"] == true;
      quizData = status;
      quizLoading = false;
    });
  }

  Future<void> _openQuiz() async {
    final result = await Navigator.pushNamed(context, '/quiz');
    if (result == true) {
      await loadQuizStatus();
      await loadPrediction();
      await loadCycles();
    }
  }

  Future<void> _loadCachedUserInfo() async {
    final info = await ApiService.loadUserInfo();
    if (!mounted) return;
    setState(() {
      _cachedUsername = info["username"];
      _cachedEmail = info["email"];
    });
  }

  void _openProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          cachedUsername: _cachedUsername,
          cachedEmail: _cachedEmail,
          quizData: quizData,
        ),
      ),
    );
  }

  String get _profileInitial {
    final name = _cachedUsername;
    if (name?.isNotEmpty == true) {
      return name!.substring(0, 1).toUpperCase();
    }
    return 'H';
  }

  DateTime? get _predictedStart {
    final raw = prediction?['predicted_next_period'];
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  int? get _latestCycleLength {
    if (cycles.isEmpty) return null;
    final value = cycles.first['cycle_length'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  int? get _latestPeriodLength {
    if (cycles.isEmpty) return null;
    final value = cycles.first['period_length'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Set<String> _buildPredictedDates() {
    final dates = <String>{};
    final start = _predictedStart;
    final period = _latestPeriodLength;
    if (start == null || period == null || period <= 0) {
      return dates;
    }
    for (var i = 0; i < period; i++) {
      final date = start.add(Duration(days: i));
      dates.add(_dateKey(date));
    }
    return dates;
  }

  Set<String> _buildLoggedDates() {
    final dates = <String>{};
    for (final cycle in cycles) {
      final raw = cycle['start_date'];
      if (raw is String) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          dates.add(_dateKey(parsed));
        }
      }
    }
    return dates;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openCalendarDetail() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return CalendarDetailSheet(
          cycles: cycles,
          prediction: prediction,
          onCycleSaved: ({Map<String, dynamic>? cycle}) async {
            final saved = await _handleCycleForm(entry: cycle);
            if (saved && mounted) {
              Navigator.pop(sheetContext);
            }
            return saved;
          },
        );
      },
    );
  }

  void _showPhaseDetails(Map<String, dynamic> prediction) {
    final int cycleDay =
        int.tryParse(prediction['cycle_day']?.toString() ?? '') ?? 1;
    final int cycleLength =
        int.tryParse(prediction['cycle_length']?.toString() ?? '') ?? 28;
    final String phase = prediction['current_phase']?.toString() ?? 'Tracking';
    final double progress = (cycleDay / cycleLength).clamp(0.0, 1.0);
    final double confidence =
        (double.tryParse(prediction['confidence']?.toString() ?? '') ?? 0.0)
            .clamp(0.0, 1.0);
    final Map<String, List<String>> tips = {
      'menstrual': [
        'Hydrate often, choose softer fabrics, and log flow info.',
        'Gentle stretching can ease cramps without fatigue.',
      ],
      'follicular': [
        'Energy is rising—plan active days and strength work.',
        'Track sleep, it supports estrogen stability.',
      ],
      'ovulation': [
        'Stay mindful of hydration and ovulation symptoms.',
        'You may feel a burst of energy—book focused work.',
      ],
      'luteal': [
        'Support with magnesium-rich snacks to ease tension.',
        'Wind down earlier; sleep quality improves hormone balance.',
      ],
      'tracking': [
        'Log every symptom so we can personalize your phases.',
        'Add mood notes to spot patterns over time.',
      ],
    };
    final String phaseKey = phase.toLowerCase();
    final List<String> phaseTips = tips[phaseKey] ?? tips['tracking']!;

      showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      builder: (sheetContext) {
        final List<_RecentCycleSummary> recentSummaries =
            _recentCycleSummaries().take(3).toList();
        final _RecentCycleSummary? latestCycle =
            recentSummaries.isNotEmpty ? recentSummaries.first : null;
        final List<_PhaseSegment> phaseSegments = _phaseSegmentsForCycle(
          cycleLength: cycleLength,
          periodDays: latestCycle?.periodLength.toDouble() ?? 5.0,
        );

        return SafeArea(
          child: Container(
            color: HerCyclePalette.light,
            child: Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: HerCyclePalette.deep.withOpacity(0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: HerCyclePalette.magenta.withOpacity(0.25),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 64,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 18),
                              decoration: BoxDecoration(
                                color: HerCyclePalette.magenta.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phase insights',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: HerCyclePalette.deep,
                                    ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                icon: const Icon(Icons.close),
                                color: HerCyclePalette.magenta,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You are on day $cycleDay of $cycleLength, currently in the $phase phase.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: HerCyclePalette.magenta),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _infoChip('Phase', phase),
                              _infoChip(
                                'Confidence',
                                '${(confidence * 100).round()}%',
                              ),
                              _infoChip('Cycle length', '$cycleLength days'),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildPhaseSegmentChart(
                            sheetContext,
                            phaseSegments,
                            cycleLength,
                            displayPhase: phase,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'What this means',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: HerCyclePalette.deep,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Day $cycleDay of your cycle marks $phase. The chart above shows how the phases stack up today—$phase occupies about ${(progress * 100).round()}% of the cycle window.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: HerCyclePalette.magenta),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Recent cycle data',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: HerCyclePalette.deep,
                                ),
                          ),
                          const SizedBox(height: 12),
                          _buildRecentCycleCards(sheetContext, recentSummaries),
                          const SizedBox(height: 24),
                          Text(
                            'Suggestions',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: HerCyclePalette.deep,
                                ),
                          ),
                          const SizedBox(height: 12),
                          ...phaseTips.map(
                            (tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: HerCyclePalette.magenta,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: HerCyclePalette.magenta),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: HerCyclePalette.magenta,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 28, vertical: 12),
                                child: Text('Got it'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HerCyclePalette.deep.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: HerCyclePalette.deep,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: HerCyclePalette.magenta,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseSegmentChart(
    BuildContext context,
    List<_PhaseSegment> segments,
    int cycleLength, {
    required String displayPhase,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phase distribution',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: HerCyclePalette.magenta,
              ),
        ),
        const SizedBox(height: 12),
        ...segments.map((segment) {
          final bool isActive =
              segment.label.toLowerCase() == displayPhase.toLowerCase();
          final double ratio = (segment.days / cycleLength).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      segment.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w500,
                            color: HerCyclePalette.magenta,
                          ),
                    ),
                    Text(
                      '${segment.days.round()}d',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: HerCyclePalette.magenta,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? HerCyclePalette.deep : segment.color,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecentCycleCards(
    BuildContext context,
    List<_RecentCycleSummary> summaries,
  ) {
    if (summaries.isEmpty) {
      return Text(
        'Log at least one cycle to see your recent phase data.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: HerCyclePalette.magenta),
      );
    }

    final int maxCycle =
        summaries.map((entry) => entry.cycleLength).fold(28, max);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: summaries.map((summary) {
        final double cycleRatio =
            summary.cycleLength / max(maxCycle, summary.cycleLength);
        final double flowRatio =
            summary.periodLength / max(summary.cycleLength, 1);
        return SizedBox(
          width: 160,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: HerCyclePalette.deep.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: HerCyclePalette.deep.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: HerCyclePalette.magenta,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cycle ${summary.cycleLength}d',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: HerCyclePalette.magenta),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: cycleRatio.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(HerCyclePalette.deep),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Flow ${summary.periodLength}d',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: HerCyclePalette.magenta),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: flowRatio.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.16),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(HerCyclePalette.magenta),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_PhaseSegment> _phaseSegmentsForCycle({
    required int cycleLength,
    required double periodDays,
  }) {
    const double ovulationDays = 3.0;
    final double boundedPeriod =
        periodDays.clamp(2.0, cycleLength.toDouble() - 3.0);
    final double remaining = max(
      0.0,
      cycleLength.toDouble() - boundedPeriod - ovulationDays,
    );
    double lutealDays = max(7.0, remaining * 0.55);
    double follicularDays = max(4.0, remaining - lutealDays);
    if (follicularDays + lutealDays > remaining && remaining > 0) {
      final double scale = remaining / (follicularDays + lutealDays);
      lutealDays *= scale;
      follicularDays *= scale;
    }
    if (remaining <= 0) {
      lutealDays = max(3.0, cycleLength * 0.35);
      follicularDays =
          max(3.0, cycleLength.toDouble() - boundedPeriod - ovulationDays - lutealDays);
    }
    final double total =
        boundedPeriod + follicularDays + ovulationDays + lutealDays;
    final double scale = cycleLength / (total == 0 ? 1 : total);
    return [
      _PhaseSegment(
        label: 'Menstrual',
        days: boundedPeriod * scale,
        color: HerCyclePalette.magenta,
      ),
      _PhaseSegment(
        label: 'Follicular',
        days: follicularDays * scale,
        color: HerCyclePalette.blush,
      ),
      _PhaseSegment(
        label: 'Ovulation',
        days: ovulationDays * scale,
        color: HerCyclePalette.deep.withOpacity(0.85),
      ),
      _PhaseSegment(
        label: 'Luteal',
        days: lutealDays * scale,
        color: HerCyclePalette.deep,
      ),
    ];
  }

  List<_RecentCycleSummary> _recentCycleSummaries() {
    final DateFormat formatter = DateFormat.MMMd();
    final List<_RecentCycleSummary> summaries = [];
    for (final cycle in cycles) {
      final DateTime? parsed = _parseCycleDate(cycle['start_date']);
      final String label = parsed != null ? formatter.format(parsed) : 'Cycle';
      final int cycleLength = _safeParseInt(cycle['cycle_length'], fallback: 28);
      final int periodLength = _safeParseInt(cycle['period_length'], fallback: 5);
      summaries.add(_RecentCycleSummary(
        label: label,
        startDate: parsed,
        cycleLength: cycleLength,
        periodLength: periodLength,
      ));
    }
    summaries.sort((a, b) {
      final DateTime aDate = a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate = b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return summaries;
  }

  DateTime? _parseCycleDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  int _safeParseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  void _showPhaseSwipeHint(String direction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swiped $direction phase—feature coming soon'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<bool> _handleCycleForm({Map<String, dynamic>? entry}) async {
    final saved = await _showCycleForm(entry: entry);
    if (saved) {
      await loadCycles();
      await loadPrediction();
    }
    return saved;
  }

  Future<bool> _showCycleForm({Map<String, dynamic>? entry}) async {
    final formKey = GlobalKey<FormState>();
    final cycleController = TextEditingController(
      text: entry?['cycle_length']?.toString() ?? '28',
    );
    final periodController = TextEditingController(
      text: entry?['period_length']?.toString() ?? '5',
    );
    DateTime selectedDate;
    if (entry != null) {
      final parsed = DateTime.tryParse(entry['start_date'] ?? '');
      selectedDate = parsed ?? DateTime.now();
    } else {
      selectedDate = DateTime.now();
    }
    bool isSaving = false;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(entry == null ? 'Log period' : 'Update period'),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Start date'),
                        subtitle: Text(DateFormat.yMMMd().format(selectedDate)),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cycleController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cycle length (days)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: periodController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Period length (days)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            final cycleLength = int.tryParse(
                              cycleController.text,
                            );
                            final periodLength = int.tryParse(
                              periodController.text,
                            );
                            if (cycleLength == null || periodLength == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter valid numbers'),
                                ),
                              );
                              return;
                            }
                            if (cycleLength < 15 || cycleLength > 60) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Cycle length should be between 15–60 days',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (periodLength < 1 || periodLength > 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Period length should be between 1–10 days',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (periodLength > cycleLength) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Period length cannot exceed cycle length',
                                  ),
                                ),
                              );
                              return;
                            }
                            setState(() {
                              isSaving = true;
                            });
                            final payloadDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                            ).toIso8601String().split('T')[0];
                            final success = entry == null
                                ? await ApiService.saveCycle(
                                    startDate: payloadDate,
                                    cycleLength: cycleLength,
                                    periodLength: periodLength,
                                  )
                                : await ApiService.updateCycle(
                                    id: entry['id'],
                                    startDate: payloadDate,
                                    cycleLength: cycleLength,
                                    periodLength: periodLength,
                                  );
                            if (!mounted) return;
                            if (success) {
                              Navigator.pop(context, true);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to save cycle'),
                                ),
                              );
                              setState(() {
                                isSaving = false;
                              });
                            }
                          },
                    child: SizedBox(
                      height: 24,
                      child: isSaving
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : Text(
                              entry == null ? 'Log period' : 'Update period',
                            ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
      return result ?? false;
    } finally {
      cycleController.dispose();
      periodController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eira '),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _openProfileScreen,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: HerCyclePalette.magenta,
                  child: Text(
                    _profileInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (predictionLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 24),
            ] else if (prediction != null) ...[
              PredictionCard(
                data: prediction!,
                onCardTap: () => _showPhaseDetails(prediction!),
                onSwipePrevious: () => _showPhaseSwipeHint('previous'),
                onSwipeNext: () => _showPhaseSwipeHint('next'),
              ),
            ] else ...[
              const Center(child: Text('No prediction available')),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 16),
            CalendarPreview(
              month: DateTime.now(),
              predictedDates: _buildPredictedDates(),
              loggedDates: _buildLoggedDates(),
              cycleLength: _latestCycleLength,
              periodLength: _latestPeriodLength,
              nextPeriod: _predictedStart,
              onTap: _openCalendarDetail,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-cycle').then((_) async {
                  await loadPrediction();
                  await loadCycles();
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text(
                'Add Cycle Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
            if (!quizLoading && !quizCompleted) ...[
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: HerCyclePalette.light.withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.rocket_launch,
                            color: HerCyclePalette.deep,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Improve your predictions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete the menstrual health quiz to surface symptoms, pain, and flow info that sharpens future predictions.',
                        style: TextStyle(color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Optional · 2 min',
                            style: TextStyle(color: Colors.grey),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: HerCyclePalette.deep,
                            ),
                            onPressed: _openQuiz,
                            child: const Text('Take quiz'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (cycles.isNotEmpty) ...[
              PredictionCharts(cycles: cycles, prediction: prediction),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class CalendarDetailSheet extends StatefulWidget {
  final List<dynamic> cycles;
  final Map<String, dynamic>? prediction;
  final Future<bool> Function({Map<String, dynamic>? cycle}) onCycleSaved;

  const CalendarDetailSheet({
    super.key,
    required this.cycles,
    this.prediction,
    required this.onCycleSaved,
  });

  @override
  State<CalendarDetailSheet> createState() => _CalendarDetailSheetState();
}

class _CalendarDetailSheetState extends State<CalendarDetailSheet> {
  DateTime _displayedMonth = DateTime.now();
  late Set<String> _loggedDayKeys;
  late Set<String> _predictedDayKeys;
  late DateTime? _predictedStart;
  late int _predictedPeriodLength;

  @override
  void initState() {
    super.initState();
    _loggedDayKeys = _collectLoggedDays();
    _predictedStart = _parseDate(widget.prediction?['predicted_next_period']);
    _predictedPeriodLength =
        _safeParseInt(widget.prediction?['period_length'], fallback: 5);
    _predictedDayKeys = {};
    _updatePredictedRange();
  }

  void _goToPreviousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  List<String> get _weekLabels => const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  Set<String> _collectLoggedDays() {
    final dates = <String>{};
    for (final cycle in widget.cycles) {
      final start = _parseDate(cycle['start_date']);
      final length = _safeParseInt(cycle['period_length'], fallback: 0);
      if (start != null && length > 0) {
        for (var i = 0; i < length; i++) {
          final day = start.add(Duration(days: i));
          dates.add(_dateKey(day));
        }
      }
    }
    return dates;
  }

  Set<String> _buildRangeKeys(DateTime start, int length) {
    final keys = <String>{};
    for (var i = 0; i < length; i++) {
      keys.add(_dateKey(start.add(Duration(days: i))));
    }
    return keys;
  }

  String _dateKey(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  int _safeParseInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  List<DateTime> _calendarDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final startOffset = firstOfMonth.weekday % 7;
    final startDay = firstOfMonth.subtract(Duration(days: startOffset));
    return List.generate(42, (index) => startDay.add(Duration(days: index)));
  }

  void _updatePredictedRange() {
    _predictedDayKeys.clear();
    if (_predictedStart == null) return;
    _predictedDayKeys.addAll(_buildRangeKeys(_predictedStart!, _predictedPeriodLength));
  }

  @override
  Widget build(BuildContext context) {
    final String phase = widget.prediction?['current_phase']?.toString() ?? 'Tracking';
    final double confidence =
        (double.tryParse(widget.prediction?['confidence']?.toString() ?? '') ?? 0.0)
            .clamp(0.0, 1.0);
    final DateTime? today = DateTime.now();
    final height = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: HerCyclePalette.light,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Period Calendar',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: HerCyclePalette.deep,
                            ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        color: HerCyclePalette.deep,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _predictedStart != null
                        ? 'Next prediction: ${DateFormat.yMMMMd().format(_predictedStart!)}'
                        : 'Next prediction: —',
                    style: const TextStyle(color: HerCyclePalette.magenta),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _infoBubble('Phase', phase, background: Colors.white),
                      _infoBubble('Cycle day', widget.prediction?['cycle_day']?.toString() ?? '—',
                          background: HerCyclePalette.magenta.withOpacity(0.12),
                          textColor: HerCyclePalette.magenta),
                      _infoBubble('Confidence', '${(confidence * 100).round()}%',
                          background: HerCyclePalette.magenta.withOpacity(0.15),
                          textColor: HerCyclePalette.magenta),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildMonthSelector(),
                  const SizedBox(height: 12),
                  _buildCalendarGrid(today),
                  const SizedBox(height: 14),
                  _buildLegend(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      children: [
        IconButton(
          onPressed: _goToPreviousMonth,
          icon: Icon(Icons.chevron_left, color: HerCyclePalette.deep),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_displayedMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: HerCyclePalette.deep,
            ),
          ),
        ),
        IconButton(
          onPressed: _goToNextMonth,
          icon: Icon(Icons.chevron_right, color: HerCyclePalette.deep),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(DateTime? today) {
    final days = _calendarDays(_displayedMonth);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weekLabels
              .map(
                (label) => Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: HerCyclePalette.deep.withOpacity(0.6),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) => _buildCalendarDay(days[index], today),
        ),
      ],
    );
  }

  Widget _buildCalendarDay(DateTime day, DateTime? today) {
    final bool isCurrentMonth = day.month == _displayedMonth.month;
    final bool isPredicted = _predictedDayKeys.contains(_dateKey(day));
    final bool isLogged = _loggedDayKeys.contains(_dateKey(day));
    final bool isToday = today != null && DateUtils.isSameDay(day, today);
    final bgColor = isPredicted
        ? HerCyclePalette.magenta.withOpacity(0.9)
        : isLogged
            ? HerCyclePalette.blush.withOpacity(0.4)
            : Colors.transparent;
    final textColor = isPredicted
        ? Colors.white
        : isCurrentMonth
            ? HerCyclePalette.deep
            : HerCyclePalette.deep.withOpacity(0.4);
    return GestureDetector(
      onTap: () => _showDayActions(day),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: HerCyclePalette.magenta, width: 2)
                : Border.all(color: Colors.transparent),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (isLogged)
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 18,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HerCyclePalette.deep,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDayActions(DateTime day) {
    final isPredicted = _predictedDayKeys.contains(_dateKey(day));
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(day),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: HerCyclePalette.deep,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Update this calendar entry to help the model learn.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: HerCyclePalette.magenta),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await _logPeriodStart(day);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HerCyclePalette.magenta,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Log period start here'),
                ),
              ),
              const SizedBox(height: 12),
              if (isPredicted)
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _adjustPredictedStart(day);
                  },
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: HerCyclePalette.deep.withOpacity(0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Mark as corrected prediction'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logPeriodStart(DateTime day) async {
    final defaultCycle = _safeParseInt(widget.prediction?['cycle_length'], fallback: 28);
    final defaultPeriod = _safeParseInt(widget.prediction?['period_length'], fallback: 5);
    await widget.onCycleSaved(
      cycle: {
        'start_date': day.toIso8601String(),
        'cycle_length': defaultCycle,
        'period_length': defaultPeriod,
      },
    );
  }

  void _adjustPredictedStart(DateTime day) {
    setState(() {
      _predictedStart = day;
      _updatePredictedRange();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prediction adjusted to ${DateFormat.yMMMd().format(day)}'),
        backgroundColor: HerCyclePalette.magenta,
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _legendItem('Predicted period', HerCyclePalette.magenta),
        _legendItem('Logged flow', HerCyclePalette.blush),

      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _infoBubble(
    String label,
    String value, {
    Color background = Colors.white,
    Color textColor = HerCyclePalette.deep,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HerCyclePalette.deep.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

}

class _PhaseSegment {
  final String label;
  final double days;
  final Color color;

  const _PhaseSegment({
    required this.label,
    required this.days,
    required this.color,
  });
}

class _RecentCycleSummary {
  final String label;
  final DateTime? startDate;
  final int cycleLength;
  final int periodLength;

  const _RecentCycleSummary({
    required this.label,
    this.startDate,
    required this.cycleLength,
    required this.periodLength,
  });
}
