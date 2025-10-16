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
  {"code": "GB", "name": "United Kingdom"},
  {"code": "CN", "name": "China"},
];

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF001AFF),
              Color(0xFF020310),
              Color(0xFF0A0B2E),
            ],
          ),
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
                    // Logo
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
                    const Text('Create your account',
                        style: AuthTheme.subtitleStyle),
                    const SizedBox(height: 35),

                    // Rounded background container
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
                          // Username
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

                          // Email
                          TextFormField(
                            controller: emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: AuthTheme.textFieldDecoration(
                              hintText: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an email';
                              } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          // Country Dropdown (only addition)
                          DropdownButtonFormField<String>(
                            value: _selectedCountryCode,
                            decoration: AuthTheme.textFieldDecoration(
                              hintText: 'Country (optional)',
                              icon: Icons.public,
                            ),
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: Colors.black.withOpacity(0.95),
                            items: countryList
                                .map((country) => DropdownMenuItem(
                              value: country['code'],
                              child: Text(
                                country['name']!,
                                style: const TextStyle(color: Colors.white), // <-- white text for visibility
                              ),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCountryCode = value ?? "";
                              });
                            },
                          ),
                          const SizedBox(height: 18),

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
                          const SizedBox(height: 30),

                          // Sign Up Button
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
                                    countryCode: _selectedCountryCode, // <--- added
                                  );
                                  if (result['ok'] == true) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                          content: Text('Account created!')));
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) =>
                                              HomeFeed(username: username),
                                        ),
                                      );
                                    }
                                  } else {
                                    final err = (result['error'] ?? 'Signup failed').toString();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text(err)));
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Network error: $e')),
                                    );
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
                                  : const Text('Sign Up',
                                  style: TextStyle(fontSize: 18, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Navigate to Login
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