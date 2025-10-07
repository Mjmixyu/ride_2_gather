import 'package:flutter/material.dart';
import 'package:ride2gather/views/signUp_view.dart';

//this function/class call the app and sets title, theme, color, fonts etc.
//the first page that get's shown is the signup - will change once user is created and change to login
void main() {
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
