/**
 * constraints.dart
 *
 * File-level Dartdoc:
 * Central place for reusable text styles used by the login / auth screens.
 * Each function returns a TextStyle that depends on the given Size or is fixed.
 * These helpers keep typography consistent and allow responsive sizing based on
 * the current screen dimensions.
 *
 * Each function below includes a short description and @param / @return tags.
 */
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Title style used on the login screen. Scales with the provided Size.
///
/// @param size The Size of the current screen or container used to compute font size.
/// @return TextStyle A bold, large title style using the Ubuntu font.
TextStyle kLoginTitleStyle(Size size) => GoogleFonts.ubuntu(
  fontSize: size.height * 0.060,
  fontWeight: FontWeight.bold,
);

/// Subtitle style used on the login screen. Scales with the provided Size.
///
/// @param size The Size of the current screen or container used to compute font size.
/// @return TextStyle A medium-sized subtitle style using the Ubuntu font.
TextStyle kLoginSubtitleStyle(Size size) => GoogleFonts.ubuntu(
  fontSize: size.height * 0.030,
);

/// Terms and privacy text style for small helper text.
///
/// @param size (unused) Kept for signature consistency with other style helpers.
/// @return TextStyle Small grey text with increased line height for readability.
TextStyle kLoginTermsAndPrivacyStyle(Size size) =>
    GoogleFonts.ubuntu(fontSize: 15, color: Colors.grey, height: 1.5);

/// Style for the "Have an account" helper text.
///
/// @param size The Size of the current screen or container used to compute font size.
/// @return TextStyle A small black text style using the Ubuntu font.
TextStyle kHaveAnAccountStyle(Size size) =>
    GoogleFonts.ubuntu(fontSize: size.height * 0.022, color: Colors.black);

/// Style used for "Login or Sign Up" interactive text.
///
/// @param size The Size of the current screen or container used to compute font size.
/// @return TextStyle A slightly emphasized purple style for actionable text.
TextStyle kLoginOrSignUpTextStyle(
    Size size,
    ) =>
    GoogleFonts.ubuntu(
      fontSize: size.height * 0.022,
      fontWeight: FontWeight.w500,
      color: Colors.deepPurpleAccent,
    );

/// Generic text style for input fields.
///
/// @return TextStyle A simple black text style for form inputs.
TextStyle kTextFormFieldStyle() => const TextStyle(color: Colors.black);