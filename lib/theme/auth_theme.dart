import 'package:flutter/material.dart';

class AuthTheme {
  // Background gradient matching login / signup
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF001AFF),
      Color(0xFF020310),
      Color(0xFF0A0B2E),
    ],
  );

  // Text field style
  static InputDecoration textFieldDecoration({
    required String hintText,
    required IconData icon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A1A3C),
      hintText: hintText,
      hintStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF007BFF), width: 1.5),
      ),
    );
  }

  // Button style (visually closer to the signup button - pill, strong blue color, subtle border & elevation)
  static ButtonStyle mainButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    backgroundColor: const Color(0xFF007BFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
      side: BorderSide(color: Colors.black.withOpacity(0.35), width: 1.2),
    ),
    elevation: 6,
    shadowColor: Colors.black54,
  );

  // Text styles
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );

  static const TextStyle linkStyle = TextStyle(
    color: Color(0xFF007BFF),
    fontWeight: FontWeight.w600,
  );
}