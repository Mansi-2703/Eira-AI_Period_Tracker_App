import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum LogState { notLogged, partiallyLogged, fullyLogged }

class DailyLogCard extends StatefulWidget {
  final DateTime date;
  final Function(Map<String, dynamic>)? onLogSaved;

  const DailyLogCard({super.key, required this.date, this.onLogSaved});

  @override
  State<DailyLogCard> createState() => _DailyLogCardState();
}

class _DailyLogCardState extends State<DailyLogCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  int _currentStep = 0;
  LogState _logState = LogState.notLogged;

  // Log data
  String? _selectedMood;
  String? _selectedFlow;
  String? _selectedEnergy;
  final Set<String> _selectedSymptoms = {};

  late AnimationController _animationController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _saveLog() {
    final logData = {
      'date': widget.date.toIso8601String(),
      'mood': _selectedMood,
      'flow': _selectedFlow,
      'energy': _selectedEnergy,
      'symptoms': _selectedSymptoms.toList(),
    };

    setState(() {
      _logState = LogState.fullyLogged;
      _isExpanded = false;
      _currentStep = 0;
      _animationController.reverse();
    });

    widget.onLogSaved?.call(logData);

    // Show confirmation for 2 seconds, then collapse
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _editLog() {
    setState(() {
      _isExpanded = true;
      _currentStep = 0;
      _animationController.forward();
    });
  }

  bool get _canProceedFromCurrentStep {
    switch (_currentStep) {
      case 0:
        return _selectedMood != null;
      case 1:
        return _selectedFlow != null && _selectedEnergy != null;
      case 2:
        return true; // Symptoms are optional
      default:
        return false;
    }
  }

  bool get _hasPartialData {
    return _selectedMood != null ||
        _selectedFlow != null ||
        _selectedEnergy != null ||
        _selectedSymptoms.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE d MMM');
    final formattedDate = dateFormat.format(widget.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: _logState == LogState.fullyLogged
            ? const LinearGradient(
                colors: [
                  Color(0xFFF3E5F5),
                  Color(0xFFFCE4EC),
                  Color(0xFFFFFFFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              )
            : const LinearGradient(
                colors: [Color(0xFFFCE4EC), Color(0xFFF3E5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header - always visible
            _buildHeader(formattedDate),

            // Expandable content
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isExpanded ? _buildExpandedContent() : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    return InkWell(
      onTap: _logState == LogState.fullyLogged ? null : _toggleExpanded,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Today's log",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _logState == LogState.fullyLogged
                              ? const Color(0xFF8E24AA)
                              : const Color(0xFFD81B60),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (!_isExpanded && _logState != LogState.fullyLogged)
                    Text(
                      _hasPartialData
                          ? _getPreviewText()
                          : 'Tap to log your mood, flow & symptoms',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
            // Status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _logState == LogState.fullyLogged
                    ? const Color(0xFFAB47BC)
                    : Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_logState == LogState.fullyLogged)
                    const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.white,
                    ),
                  if (_logState == LogState.fullyLogged)
                    const SizedBox(width: 4),
                  Text(
                    _logState == LogState.fullyLogged
                        ? 'Logged ✓'
                        : 'Not logged',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _logState == LogState.fullyLogged
                          ? Colors.white
                          : const Color(0xFFD81B60),
                    ),
                  ),
                  if (!_isExpanded && _logState != LogState.fullyLogged)
                    const SizedBox(width: 4),
                  if (!_isExpanded && _logState != LogState.fullyLogged)
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: const Color(0xFFD81B60),
                    ),
                ],
              ),
            ),
            if (_logState == LogState.fullyLogged) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: const Color(0xFF8E24AA),
                onPressed: _editLog,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getPreviewText() {
    final parts = <String>[];
    if (_selectedMood != null) parts.add('Mood: $_selectedMood');
    if (_selectedFlow != null) parts.add('Flow: $_selectedFlow');
    if (_selectedEnergy != null) parts.add('Energy: $_selectedEnergy');
    if (_selectedSymptoms.isNotEmpty) {
      parts.add('${_selectedSymptoms.length} symptoms');
    }
    return parts.join(' • ');
  }

  Widget _buildExpandedContent() {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.5)),
      child: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(3, (index) {
                final isActive = index == _currentStep;
                final isCompleted = index < _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: isActive || isCompleted
                          ? const Color(0xFFD81B60)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Step content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStepContent(),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _previousStep,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: _canProceedFromCurrentStep ? _nextStep : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Next'),
                  ),
                if (_currentStep == 2)
                  ElevatedButton(
                    onPressed: _canProceedFromCurrentStep ? _saveLog : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFAB47BC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMoodStep();
      case 1:
        return _buildFlowEnergyStep();
      case 2:
        return _buildSymptomsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMoodStep() {
    final moods = [
      {'emoji': '😊', 'label': 'Happy'},
      {'emoji': '😌', 'label': 'Calm'},
      {'emoji': '😔', 'label': 'Sad'},
      {'emoji': '😰', 'label': 'Anxious'},
      {'emoji': '😤', 'label': 'Irritable'},
      {'emoji': '😫', 'label': 'Tired'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How are you feeling?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: moods.length,
          itemBuilder: (context, index) {
            final mood = moods[index];
            final isSelected = _selectedMood == mood['label'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedMood = mood['label'] as String;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD81B60).withOpacity(0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD81B60)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mood['emoji'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mood['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFFD81B60)
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFlowEnergyStep() {
    final flowOptions = [
      {'icon': Icons.opacity, 'label': 'Light'},
      {'icon': Icons.water_drop, 'label': 'Medium'},
      {'icon': Icons.water, 'label': 'Heavy'},
      {'icon': Icons.block, 'label': 'None'},
    ];

    final energyOptions = [
      {'icon': Icons.battery_full, 'label': 'High'},
      {'icon': Icons.battery_3_bar, 'label': 'Medium'},
      {'icon': Icons.battery_1_bar, 'label': 'Low'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Flow level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: flowOptions.map((option) {
            final isSelected = _selectedFlow == option['label'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedFlow = option['label'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD81B60).withOpacity(0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD81B60)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFFD81B60)
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFFD81B60)
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Energy level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: energyOptions.map((option) {
            final isSelected = _selectedEnergy == option['label'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedEnergy = option['label'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD81B60).withOpacity(0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD81B60)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      size: 18,
                      color: isSelected
                          ? const Color(0xFFD81B60)
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFFD81B60)
                            : Colors.grey[700],
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSymptomsStep() {
    final symptoms = [
      'Cramps',
      'Headache',
      'Bloating',
      'Acne',
      'Tender breasts',
      'Fatigue',
      'Back pain',
      'Nausea',
      'Food cravings',
      'Mood swings',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Any symptoms? (optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: symptoms.map((symptom) {
            final isSelected = _selectedSymptoms.contains(symptom);
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSymptoms.remove(symptom);
                  } else {
                    _selectedSymptoms.add(symptom);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFD81B60).withOpacity(0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFD81B60)
                        : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  symptom,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected
                        ? const Color(0xFFD81B60)
                        : Colors.grey[700],
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
