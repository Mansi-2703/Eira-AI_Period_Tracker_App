import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../theme/hercycle_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _scheduleNextRoute();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HerCyclePalette.light,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
                    Image.asset(
                    'assets/images/logo.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
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
