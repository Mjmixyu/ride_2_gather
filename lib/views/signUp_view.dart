/**
 * signUp_view.dart
 *
 * File-level Dartdoc:
 * Provides the SignUpView widget for user registration. This file contains a
 * responsive sign-up form that collects username, email, password and an
 * optional country code. It validates input, calls AuthApi.signup, and on
 * success navigates to the HomeFeed. Uses AuthTheme for consistent styling.
 *
 * Note: preserves a developer reminder about restarting the server as requested.
 */
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/simple_ui_controller.dart';
import '../theme/auth_theme.dart';
import '../core/auth_api.dart';
import '../core/homeFeed_routing.dart';
import 'login_view.dart';

// fyi signup country_code works - have to restart node.js AND GENERALLY PLS ALWAYS START (or automate)
const List<Map<String, String>> countryList = [
  {"code": "", "name": "Select country (optional)"},
  {"code": "DE", "name": "Germany"},
  {"code": "US", "name": "United States"},
  {"code": "FR", "name": "France"},
  {"code": "UK", "name": "United Kingdom"},
  {"code": "IT", "name": "Italy"},
];

/// SignUpView is a form that allows creating a new user account.
///
/// It validates username, email and password, and provides a country selector.
/// On successful signup it navigates to the HomeFeed screen.
class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

/// State for SignUpView managing controllers, loading state and selected country.
class _SignUpViewState extends State<SignUpView> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String _selectedCountryCode = "";

  @override
  void dispose() {
    nameController.dispose();
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
          gradient: AuthTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                    const Text('Sign Up', style: AuthTheme.titleStyle),
                    const SizedBox(height: 6),
                    const Text('Create your account', style: AuthTheme.subtitleStyle),
                    const SizedBox(height: 35),

                    // Main rounded card containing the input fields and button
                    Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Username field with validation
                          TextFormField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: AuthTheme.textFieldDecoration(
                              hintText: 'Username',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter username';
                              } else if (value.length < 4) {
                                return 'At least 4 characters';
                              } else if (value.length > 13) {
                                return 'Max 13 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Email field with basic validation
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: AuthTheme.textFieldDecoration(
                              hintText: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Password field with visibility toggle and validation
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
                                    simpleUIController.isObscure.value ? Icons.visibility : Icons.visibility_off,
                                    color: Colors.white70,
                                  ),
                                  onPressed: () => simpleUIController.isObscureActive(),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                } else if (value.length < 6) {
                                  return 'At least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Country selector dropdown (optional)
                          DropdownButtonFormField<String>(
                            value: _selectedCountryCode,
                            dropdownColor: const Color(0xFF1A1A3C),
                            style: const TextStyle(color: Colors.white),
                            decoration: AuthTheme.textFieldDecoration(
                              hintText: 'Country (optional)',
                              icon: Icons.public,
                            ),
                            items: countryList
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                value: c['code'],
                                child: Text(c['name'] ?? ''),
                              ),
                            )
                                .toList(),
                            onChanged: (val) {
                              setState(() => _selectedCountryCode = val ?? "");
                            },
                          ),
                          const SizedBox(height: 20),

                          // Sign Up button that validates and calls AuthApi.signup
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: AuthTheme.mainButtonStyle,
                              onPressed: _loading
                                  ? null
                                  : () async {
                                if (!_formKey.currentState!.validate()) return;
                                final username = nameController.text.trim();
                                final email = emailController.text.trim();
                                final password = passwordController.text;
                                setState(() => _loading = true);
                                try {
                                  final result = await AuthApi.signup(
                                    email: email,
                                    username: username,
                                    password: password,
                                    countryCode: _selectedCountryCode,
                                  );
                                  if (result['ok'] == true) {
                                    final user = result['data'];
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Account created!')),
                                      );
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => HomeFeed(username: username, userId: user['id']),
                                        ),
                                      );
                                    }
                                  } else {
                                    final err = (result['error'] ?? 'Signup failed').toString();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(content: Text('Network error: $e')));
                                  }
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                              child: _loading
                                  ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Link to navigate to the login screen
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const LoginView()),
                        );
                        nameController.clear();
                        emailController.clear();
                        passwordController.clear();
                        _formKey.currentState?.reset();
                        simpleUIController.isObscure.value = true;
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(text: 'Log In', style: AuthTheme.linkStyle),
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