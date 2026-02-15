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
      backgroundColor: HerCyclePalette.light.withOpacity(0.25),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _pulseAnim,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: HerCyclePalette.vibrantGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: HerCyclePalette.deep.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.heart_broken,
                        color: Colors.white,
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
                            fontWeight: FontWeight.w600,
                            color: HerCyclePalette.deep,
                          ),
                        ),
                        Text(
                          "Step ${currentStep + 1} of ${questions.length}",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: submitQuiz,
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: HerCyclePalette.deep.withOpacity(0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      backgroundColor: HerCyclePalette.light.withOpacity(0.7),
                      label: Text(
                        q["title"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      q["question"],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: q["options"].map<Widget>((option) {
                        final bool isSelected =
                            answers[q["key"]] == option["value"];
                        return ChoiceChip(
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          label: Text(
                            option["label"],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : HerCyclePalette.deep,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: HerCyclePalette.deep,
                          surfaceTintColor: Colors.white,
                          backgroundColor: HerCyclePalette.light.withOpacity(
                            0.6,
                          ),
                          onSelected: (_) => nextStep(option["value"]),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    const Text(
                      "Your answers stay private and only help us tune cycle predictions.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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
