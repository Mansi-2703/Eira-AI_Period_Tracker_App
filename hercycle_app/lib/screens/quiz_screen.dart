import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int currentStep = 0;
  final Map<String, dynamic> answers = {};

  final List<Map<String, dynamic>> questions = [
    {
      "key": "flow_intensity",
      "title": "Flow",
      "question": "How would you describe your menstrual flow?",
      "options": [
        {"label": "Very light", "value": 1},
        {"label": "Light", "value": 2},
        {"label": "Moderate", "value": 3},
        {"label": "Heavy", "value": 4},
        {"label": "Very heavy", "value": 5},
      ],
    },
    {
      "key": "pad_change_frequency",
      "title": "Flow",
      "question": "How often do you change your pad/tampon on heavy days?",
      "options": [
        {"label": "Every 6+ hrs", "value": 1},
        {"label": "Every 4-5 hrs", "value": 2},
        {"label": "Every 2-3 hrs", "value": 3},
        {"label": "Hourly", "value": 4},
        {"label": "Less than hourly", "value": 5},
      ],
    },
    {
      "key": "flooding",
      "title": "Flow",
      "question": "Do you experience flooding or soaking through?",
      "options": [
        {"label": "Never", "value": 0},
        {"label": "Rarely", "value": 1},
        {"label": "Often", "value": 2},
      ],
    },
    {
      "key": "clot_size",
      "title": "Flow",
      "question": "Are you passing clots larger than a quarter?",
      "options": [
        {"label": "No clots", "value": 0},
        {"label": "Small clots", "value": 1},
        {"label": "Large clots", "value": 2},
      ],
    },
    {
      "key": "period_duration",
      "title": "Duration",
      "question": "How many days does your period usually last?",
      "options": [
        {"label": "1–2 days", "value": 2},
        {"label": "3–5 days", "value": 4},
        {"label": "6–7 days", "value": 6},
        {"label": "More than 7 days", "value": 8},
      ],
    },
    {
      "key": "flow_pattern",
      "title": "Consistency",
      "question": "How steady is the flow day-to-day?",
      "options": [
        {"label": "Very steady", "value": 1},
        {"label": "Some variation", "value": 2},
        {"label": "Wavy", "value": 3},
        {"label": "Very unpredictable", "value": 4},
      ],
    },
    {
      "key": "spotting_between",
      "title": "Consistency",
      "question": "Do you experience spotting between periods?",
      "options": [
        {"label": "Never", "value": 0},
        {"label": "Occasionally", "value": 1},
        {"label": "Frequently", "value": 2},
      ],
    },
    {
      "key": "cycle_regular",
      "title": "Regularity",
      "question": "How regular is your cycle from month to month?",
      "options": [
        {"label": "Very regular", "value": 1},
        {"label": "Mostly regular", "value": 2},
        {"label": "Somewhat irregular", "value": 3},
        {"label": "Very irregular", "value": 4},
      ],
    },
    {
      "key": "avg_cycle_group",
      "title": "Regularity",
      "question": "Where does your average cycle length sit?",
      "options": [
        {"label": "Short (<25d)", "value": 1},
        {"label": "Normal (25-30d)", "value": 2},
        {"label": "Long (31-35d)", "value": 3},
        {"label": "Variable (>35d)", "value": 4},
      ],
    },
    {
      "key": "pain_level",
      "title": "Pain",
      "question": "How would you rate your discomfort?",
      "options": [
        {"label": "None", "value": 0},
        {"label": "Mild", "value": 1},
        {"label": "Moderate", "value": 2},
        {"label": "Severe", "value": 3},
      ],
    },
    {
      "key": "pain_interference",
      "title": "Pain",
      "question": "Does pain interrupt daily life?",
      "options": [
        {"label": "Not at all", "value": 0},
        {"label": "Slightly", "value": 1},
        {"label": "Practically", "value": 2},
        {"label": "Completely", "value": 3},
      ],
    },
    {
      "key": "fatigue",
      "title": "Symptoms",
      "question": "Do you feel fatigue during your period?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "dizziness",
      "title": "Symptoms",
      "question": "Do you experience dizziness?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "nausea",
      "title": "Symptoms",
      "question": "Do you feel nausea?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "headaches",
      "title": "Symptoms",
      "question": "Do you get headaches?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "mood_changes",
      "title": "Emotional",
      "question": "How much do your moods swing?",
      "options": [
        {"label": "Not at all", "value": 0},
        {"label": "Slightly", "value": 1},
        {"label": "Moderately", "value": 2},
        {"label": "Highly", "value": 3},
      ],
    },
    {
      "key": "mood_impact",
      "title": "Emotional",
      "question": "Do mood swings stop you from functioning?",
      "options": [
        {"label": "No", "value": 0},
        {"label": "Sometimes", "value": 1},
        {"label": "Often", "value": 2},
      ],
    },
    {
      "key": "pcos",
      "title": "History",
      "question": "Have you been diagnosed with PCOS?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "endometriosis",
      "title": "History",
      "question": "Any endometriosis diagnosis?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "thyroid",
      "title": "History",
      "question": "Do you have thyroid concerns?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
    {
      "key": "anemia_history",
      "title": "History",
      "question": "Any anemia history?",
      "options": [
        {"label": "None", "value": 0},
        {"label": "Mild", "value": 1},
        {"label": "Moderate or higher", "value": 2},
      ],
    },
    {
      "key": "wants_health_alerts",
      "title": "Preferences",
      "question": "Do you want alerts about concerning symptoms?",
      "options": [
        {"label": "Yes", "value": true},
        {"label": "No", "value": false},
      ],
    },
  ];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void nextStep(dynamic value) {
    answers[questions[currentStep]["key"]] = value;
    if (currentStep < questions.length - 1) {
      setState(() => currentStep++);
    } else {
      submitQuiz();
    }
  }

  Future<void> submitQuiz() async {
    final success = await ApiService.submitQuiz(answers);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save quiz")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = questions[currentStep];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                gradient: HerCyclePalette.vibrantGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: HerCyclePalette.deep.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: HerCyclePalette.magenta,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Menstrual check-in",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Step ${currentStep + 1} of ${questions.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: submitQuiz,
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: HerCyclePalette.magenta.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Category Chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: HerCyclePalette.blush.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: HerCyclePalette.blush,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        q["title"],
                        style: const TextStyle(
                          color: HerCyclePalette.magenta,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Question Text - Large and Prominent
                    Text(
                      q["question"],
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: HerCyclePalette.deep,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Options List - Structured Vertical Layout
                    Expanded(
                      child: ListView.separated(
                        itemCount: q["options"].length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final option = q["options"][index];
                          final bool isSelected =
                              answers[q["key"]] == option["value"];
                          return GestureDetector(
                            onTap: () {
                              nextStep(option["value"]);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? HerCyclePalette.softGradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : HerCyclePalette.light.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? HerCyclePalette.magenta
                                      : HerCyclePalette.blush.withOpacity(0.5),
                                  width: isSelected ? 2.5 : 2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: HerCyclePalette.magenta
                                              .withOpacity(0.25),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.04),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Row(
                                children: [
                                  // Selection Indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : HerCyclePalette.blush,
                                        width: 2.5,
                                      ),
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient:
                                                    HerCyclePalette
                                                        .softGradient,
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  // Option Text
                                  Expanded(
                                    child: Text(
                                      option["label"],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : HerCyclePalette.deep,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Privacy Notice
                    const Text(
                      "Your answers stay private and only help us tune cycle predictions.",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
