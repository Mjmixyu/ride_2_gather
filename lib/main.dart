import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:ride2gather/views/signUp_view.dart';

//this function/class call the app and sets title, theme, color, fonts etc.
//the first page that get's shown is the signup - will change once user is created and change to login
void main() {
  // Make sure binding is initialized so we can tweak the image cache before UI runs
  WidgetsFlutterBinding.ensureInitialized();

  // Quick performance tweak: limit Flutter's in-memory image cache.
  // These values are conservative and reduce long-term memory use / jank.
  // Tune them if you have many small images vs. a few large avatars.
  PaintingBinding.instance.imageCache.maximumSize = 100; // number of images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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