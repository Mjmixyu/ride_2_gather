/**
 * auth_theme.dart
 *
 * File-level Dartdoc:
 * Centralizes styling used by the authentication screens (signup/login).
 * Exposes a background gradient, text field decoration factory, a main button
 * style, and commonly used text styles.
 */
import 'package:flutter/material.dart';

/**
 * Static container of theme values used on authentication views.
 *
 * Use these properties to keep visual consistency across sign-in and
 * registration screens.
 */
class AuthTheme {
  /**
   * Background gradient used on authentication screens.
   *
   * The gradient flows from top-left to bottom-right with darker blues.
   */
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF001AFF),
      Color(0xFF020310),
      Color(0xFF0A0B2E),
    ],
  );

  /**
   * Factory that returns a consistent InputDecoration for text fields.
   *
   * @param hintText The placeholder text shown when the field is empty.
   * @param icon The prefix icon displayed inside the field.
   * @return InputDecoration Preconfigured decoration for text inputs.
   */
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

  /**
   * ButtonStyle used for primary actions on auth screens.
   *
   * The style produces a pill-shaped, elevated blue button with a subtle border.
   */
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

  /**
   * Text style for large titles in auth screens.
   */
  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 26,
    fontWeight: FontWeight.bold,
  );

  /**
   * Text style for subtitles or helper text in auth screens.
   */
  static const TextStyle subtitleStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );

  /**
   * Text style used for interactive links (for example: sign in / sign up link).
   */
  static const TextStyle linkStyle = TextStyle(
    color: Color(0xFF007BFF),
    fontWeight: FontWeight.w600,
  );
}