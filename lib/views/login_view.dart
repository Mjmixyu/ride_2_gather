import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/simple_ui_controller.dart';
import '../theme/auth_theme.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SimpleUIController simpleUIController = Get.put(SimpleUIController());

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF001AFF),
              Color(0xFF0A0B2E),
              Color(0xFF020310),

            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo (rounded)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    const Text('Welcome Back', style: AuthTheme.titleStyle),
                    const SizedBox(height: 6),
                    const Text('Login to your account',
                        style: AuthTheme.subtitleStyle),
                    const SizedBox(height: 35),

                    // Email
                    TextFormField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: AuthTheme.textFieldDecoration(
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    Obx(
                          () => TextFormField(
                        controller: passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: simpleUIController.isObscure.value,
                        decoration: AuthTheme.textFieldDecoration(
                          hintText: 'Password',
                          icon: Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              simpleUIController.isObscure.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                simpleUIController.isObscureActive(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Login Button (design only)
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: AuthTheme.mainButtonStyle,
                        onPressed: () {},
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Navigation to Sign Up
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (ctx) => const SignUpView()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: 'Sign Up',
                              style: AuthTheme.linkStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
