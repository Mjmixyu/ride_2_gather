import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/simple_ui_controller.dart';
import '../theme/auth_theme.dart';
import '../core/auth_api.dart';
import '../core/homeFeed_routing.dart';
import 'signup_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController identityController = TextEditingController(); // username OR email
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void dispose() {
    identityController.dispose();
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
                    const Text('Login to your account', style: AuthTheme.subtitleStyle),
                    const SizedBox(height: 35),

                    // Rounded background container (match SignUp)
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
                          // Identity (username or email)
                          TextFormField(
                            controller: identityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: AuthTheme.textFieldDecoration(
                              hintText: 'Username or Email',
                              icon: Icons.person_outline,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter username or email';
                              }
                              return null;
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
                                  onPressed: () => simpleUIController.isObscureActive(),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: AuthTheme.mainButtonStyle,
                              onPressed: _loading
                                  ? null
                                  : () async {
                                if (!_formKey.currentState!.validate()) return;
                                setState(() => _loading = true);
                                try {
                                  final result = await AuthApi.login(
                                    identity: identityController.text.trim(),
                                    password: passwordController.text,
                                  );
                                  if (result['ok'] == true) {
                                    final user = result['data'];
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Login successful!')));
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => HomeFeed(
                                            username: user['username'],
                                            userId: user['id'],
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    final err = (result['error'] ?? 'Login failed').toString();
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
                                  : const Text(
                                'Log In',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const SignUpView()),
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