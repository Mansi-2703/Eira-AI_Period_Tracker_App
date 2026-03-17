import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';

class AddCycleScreen extends StatefulWidget {
  const AddCycleScreen({super.key});

  @override
  State<AddCycleScreen> createState() => _AddCycleScreenState();
}

class _AddCycleScreenState extends State<AddCycleScreen> {
  DateTime? lastPeriodDate;

  final cycleLengthController = TextEditingController();
  final periodLengthController = TextEditingController();

  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    cycleLengthController.text = "28"; // common average
    periodLengthController.text = "5"; // sensible default
  }

  @override
  void dispose() {
    cycleLengthController.dispose();
    periodLengthController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        lastPeriodDate = picked;
      });
    }
  }

  Future<void> saveCycle() async {
    if (lastPeriodDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select last period date")),
      );
      return;
    }

    final cycleLength = int.tryParse(cycleLengthController.text);
    final periodLength = int.tryParse(periodLengthController.text);

    if (cycleLength == null || periodLength == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid numbers")),
      );
      return;
    }

    // 🧠 Biological sanity checks
    if (cycleLength < 20 || cycleLength > 45) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cycle length should be between 20–45 days"),
        ),
      );
      return;
    }

    if (periodLength < 2 || periodLength > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Period length should be 2–10 days")),
      );
      return;
    }

    if (periodLength > cycleLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Period length cannot exceed cycle length"),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final success = await ApiService.saveCycle(
      startDate: lastPeriodDate!.toIso8601String().split('T')[0],
      cycleLength: cycleLength,
      periodLength: periodLength,
    );

    if (!mounted) return;

    setState(() => isSaving = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/quiz');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save cycle")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Cycle"),
        backgroundColor: HerCyclePalette.deep,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ListTile(
              title: Text(
                lastPeriodDate == null
                    ? "Select last period date"
                    : DateFormat.yMMMd().format(lastPeriodDate!),
                style: const TextStyle(color: HerCyclePalette.deep),
              ),
              trailing: const Icon(Icons.calendar_today, color: HerCyclePalette.magenta),
              onTap: pickDate,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: cycleLengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Cycle length (days)",
                labelStyle: const TextStyle(color: HerCyclePalette.deep),
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(color: HerCyclePalette.deep),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: periodLengthController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Period length (days)",
                labelStyle: const TextStyle(color: HerCyclePalette.deep),
                border: const OutlineInputBorder(),
              ),
              style: const TextStyle(color: HerCyclePalette.deep),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HerCyclePalette.blush,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              onPressed: isSaving ? null : saveCycle,
              child: isSaving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Save Cycle", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
