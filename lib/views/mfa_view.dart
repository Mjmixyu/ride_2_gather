// lib/views/mfa_view.dart
// Simple OTP entry & verification screen
// Usage: push this after login if user requires MFA. For mock flows you can pass expectedOtpForMock.

import 'package:flutter/material.dart';
import '../core/auth_api.dart';
import '../theme/auth_theme.dart';

class MfaView extends StatefulWidget {
  final int userId;
  final String? expectedOtpForMock;
  final VoidCallback onVerified;

  const MfaView({
    Key? key,
    required this.userId,
    this.expectedOtpForMock,
    required this.onVerified,
  }) : super(key: key);

  @override
  State<MfaView> createState() => _MfaViewState();
}

class _MfaViewState extends State<MfaView> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte OTP eingeben')));
      return;
    }
    setState(() => _loading = true);
    final res = await AuthApi.verifyMfaOtp(
      userId: widget.userId,
      code: code,
      expectedOtpForMock: widget.expectedOtpForMock,
    );
    setState(() => _loading = false);
    if (res['ok'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('MFA erfolgreich')));
      widget.onVerified();
    } else {
      final err = (res['error'] ?? 'Ungültiger Code').toString();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Verifizierungs-Code'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 18),
              const Text(
                'Gib den 6-stelligen Code ein, der an deine E‑Mail gesendet wurde.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: AuthTheme.textFieldDecoration(hintText: '123456', icon: Icons.lock_outline),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: AuthTheme.mainButtonStyle,
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text('Verifizieren', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  // allow requesting a new OTP (mock returns a visible code)
                  final req = await AuthApi.requestMfaOtp(userId: widget.userId, method: 'email');
                  if (req['ok'] == true && req['data'] is Map && req['data']['mock'] == true) {
                    final otp = req['data']['otp']?.toString() ?? '';
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mock OTP: $otp')));
                  } else if (req['ok'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP angefordert')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: ${req['error']}')));
                  }
                },
                child: const Text('Neuen Code anfordern', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}