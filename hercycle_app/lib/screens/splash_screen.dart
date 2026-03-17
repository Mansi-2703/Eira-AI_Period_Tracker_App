import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _setupBreathingAnimation();
    _scheduleNextRoute();
  }

  void _setupBreathingAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  Future<void> _scheduleNextRoute() async {
    final registered = await ApiService.hasRegistered();
    final target = registered ? '/login' : '/register';
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, target);
    });
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HerCyclePalette.light,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated breathing logo
            ScaleTransition(
              scale: _breathingAnimation,
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Eira',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: HerCyclePalette.magenta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
