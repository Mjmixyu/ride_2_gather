import 'package:flutter/material.dart';

class AuthTheme {
  // Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D0D25),
      Color(0xFF0A0A18),
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

  // Button style
  static ButtonStyle mainButtonStyle = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 14),
    backgroundColor: const Color(0xFF005DFF),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
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
