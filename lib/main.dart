import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:ride2gather/views/signUp_view.dart';
import 'services/post_repository.dart';

//this function/class call the app and sets title, theme, color, fonts etc.
//the first page that get's shown is the signup - will change once user is created and change to login
void main() async {
  // Ensure binding so we can call async init
  WidgetsFlutterBinding.ensureInitialized();

  // initialize local storage & repository
  await PostRepository.instance.init();

  // Quick performance tweak: limit Flutter's in-memory image cache.
  // These values are conservative and reduce long-term memory use / jank.
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;

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