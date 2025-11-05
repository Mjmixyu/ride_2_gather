/**
 * main_app.dart
 *
 * File-level Dartdoc:
 * Application entrypoint that initializes local storage, configures a small
 * Flutter image cache optimization, and runs the top-level MyApp widget.
 */
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:ride2gather/views/signUp_view.dart';
import 'services/post_repository.dart';

/**
 * Application entry point.
 *
 * Ensures Flutter bindings are initialized, initializes the PostRepository,
 * applies a conservative image cache limit to reduce memory usage, and starts
 * the app by running MyApp.
 */
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PostRepository.instance.init();

  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

  runApp(const MyApp());
}

/**
 * Root application widget that provides theme and initial route.
 *
 * The home screen is currently SignUpView; change this to the auth flow or
 * a logged-in landing page as appropriate.
 */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /**
   * Build the MaterialApp with theme settings and the initial home view.
   *
   * @param context BuildContext used to obtain Theme data.
   * @return Widget The configured MaterialApp instance.
   */
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ride2gather',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'Roboto',
        ),
      ),
      home: const SignUpView(),
    );
  }
}

