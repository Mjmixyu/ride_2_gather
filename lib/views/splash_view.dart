/**
 * splash_view.dart
 *
 * Simple splash screen showing a GIF (or static image fallback) on app start.
 * Place your animated GIF as assets/images/splash.gif (or change path).
 */
import 'dart:async';
import 'package:flutter/material.dart';
import 'login_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    // Show splash for 2.2 seconds and then navigate to LoginView.
    Timer(const Duration(milliseconds: 2200), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginView()));
    });
  }

  @override
  Widget build(BuildContext context) {
    // Try to load GIF; if not present, fallback to logo.png static image.
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Image.asset(
            'assets/images/splash.gif',
            gaplessPlayback: true,
            errorBuilder: (ctx, err, st) {
              return Image.asset('assets/images/logo.png', width: 200, height: 200);
            },
          ),
        ),
      ),
    );
  }
}