import 'package:flutter/material.dart';
import '../theme/hercycle_palette.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documentation'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Getting Started',
              content: 'Learn the basics of tracking your menstrual cycle with Eira.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'How to Log Your Data',
              content: 'Step-by-step guide on logging your mood, flow, energy, and symptoms.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Understanding Your Cycle',
              content: 'Learn about the different phases of your menstrual cycle and what to expect.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Cycle Predictions',
              content: 'How our AI-powered predictions help you plan ahead.',
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'Health Tips',
              content: 'Discover wellness tips tailored to each phase of your cycle.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HerCyclePalette.deep,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
