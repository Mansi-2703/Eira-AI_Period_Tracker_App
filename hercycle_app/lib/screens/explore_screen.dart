import 'package:flutter/material.dart';
import '../theme/hercycle_palette.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExploreCard(
              icon: Icons.favorite,
              title: 'Wellness Hub',
              description: 'Discover articles and tips for cycle wellness.',
            ),
            const SizedBox(height: 16),
            _buildExploreCard(
              icon: Icons.fitness_center,
              title: 'Exercise Guide',
              description: 'Workouts tailored to your cycle phase.',
            ),
            const SizedBox(height: 16),
            _buildExploreCard(
              icon: Icons.restaurant,
              title: 'Nutrition Tips',
              description: 'Foods and nutrients for each cycle phase.',
            ),
            const SizedBox(height: 16),
            _buildExploreCard(
              icon: Icons.mood,
              title: 'Mental Wellness',
              description: 'Mindfulness and self-care practices.',
            ),
            const SizedBox(height: 16),
            _buildExploreCard(
              icon: Icons.group,
              title: 'Community',
              description: 'Connect with other cycle trackers.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExploreCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: HerCyclePalette.light,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: HerCyclePalette.deep,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: HerCyclePalette.deep,
            ),
          ],
        ),
      ),
    );
  }
}
