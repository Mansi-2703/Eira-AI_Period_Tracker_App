import 'package:flutter/material.dart';
import '../data/disorders_data.dart';
import '../theme/hercycle_palette.dart';

class DisorderDetailsScreen extends StatelessWidget {
  final DisorderInfo disorder;

  const DisorderDetailsScreen({
    super.key,
    required this.disorder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header with large image
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: HerCyclePalette.light,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                disorder.imagePath,
                fit: BoxFit.cover,
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: HerCyclePalette.deep),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disorder.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: HerCyclePalette.deep,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 60,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HerCyclePalette.magenta,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    disorder.fullDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: HerCyclePalette.deep.withOpacity(0.85),
                      height: 1.8,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HerCyclePalette.magenta,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DisorderCard extends StatelessWidget {
  final DisorderInfo disorder;
  final VoidCallback onTap;

  const DisorderCard({
    super.key,
    required this.disorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                disorder.imagePath,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    disorder.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: HerCyclePalette.deep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    disorder.shortDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: HerCyclePalette.deep.withOpacity(0.7),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DisorderGridCard extends StatelessWidget {
  final DisorderInfo disorder;
  final VoidCallback onTap;

  const DisorderGridCard({
    super.key,
    required this.disorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                disorder.imagePath,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disorder.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: HerCyclePalette.deep,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        disorder.shortDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: HerCyclePalette.deep.withOpacity(0.7),
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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

class DisordersHorizontalList extends StatelessWidget {
  const DisordersHorizontalList({super.key});

  void _showDisorderDetails(BuildContext context, DisorderInfo disorder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DisorderDetailsScreen(disorder: disorder),
      ),
    );
  }

  void _showAllDisorders(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DisordersGridView(
        onDisorderTap: (disorder) {
          Navigator.pop(ctx);
          _showDisorderDetails(context, disorder);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Health Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: HerCyclePalette.deep,
                ),
              ),
              GestureDetector(
                onTap: () => _showAllDisorders(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: HerCyclePalette.magenta.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: HerCyclePalette.magenta,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: HerCyclePalette.magenta,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: disordersData.map((disorder) {
              return DisorderCard(
                disorder: disorder,
                onTap: () => _showDisorderDetails(context, disorder),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class DisordersGridView extends StatelessWidget {
  final Function(DisorderInfo) onDisorderTap;

  const DisordersGridView({
    super.key,
    required this.onDisorderTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HerCyclePalette.deep,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: HerCyclePalette.deep,
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: disordersData.length,
              itemBuilder: (ctx, index) {
                final disorder = disordersData[index];
                return GestureDetector(
                  onTap: () => onDisorderTap(disorder),
                  child: DisorderGridCard(
                    disorder: disorder,
                    onTap: () => onDisorderTap(disorder),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
