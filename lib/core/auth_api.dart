/**
 * auth_api.dart
 *
 * File-level Dartdoc:
 * Provides API helper methods for user authentication and profile actions.
 * This file contains a single AuthApi class with static methods to signup,
 * login, fetch user data, update user settings, and upload profile pictures.
 *
 * Each method returns a Map<String, dynamic> with an 'ok' boolean and either
 * 'data' or 'error' fields to indicate success or failure.
 */
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

/// A collection of static methods to call the authentication-related server endpoints.
///
/// NOTE: Methods now accept an optional http.Client? client parameter (default null).
/// This keeps production behavior unchanged while allowing tests to inject a MockClient.
class AuthApi {
  static const String _base = 'http://10.0.2.2:3000';

  static Future<bool> _serverAvailable(http.Client c) async {
    try {
      final uri = Uri.parse('$_base/health');
      final res = await c.get(uri).timeout(const Duration(seconds: 2));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Sends a signup request to the server and returns the parsed response.
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
    String countryCode = "",
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/signup');
    try {
      final res = await c.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'country_code': countryCode,
        }),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 201) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'Signup failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  /// Sends a login request using either username or email as the identity.
  static Future<Map<String, dynamic>> login({
    required String identity,
    required String password,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/login');
    try {
      final res = await c.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': identity, 'password': password}),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'Login failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      // Network fallback: return mock user for quick UI testing
      // WARNING: remove or replace with real backend in production
      if (identity == 'test' && password == 'test123') {
        return {
          'ok': true,
          'data': {'id': 1, 'username': 'test', 'email': 'test@example.com', 'mfa_enabled': false}
        };
      }
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  /// Retrieves a user's public profile by username.
  static Future<Map<String, dynamic>> getUserByUsername(
      String username, {
        http.Client? client,
      }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/user/$username');
    try {
      final res = await c.get(uri);
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'Get user failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  /// Updates the given user's settings such as bio and selected bike name.
  static Future<Map<String, dynamic>> updateUserSettings({
    required int userId,
    String? bio,
    String? bikeName,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/user/$userId');
    try {
      final res = await c.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'bio': bio, 'bike_name': bikeName}),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'Update failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  /// Uploads a profile picture file using multipart/form-data.
  static Future<Map<String, dynamic>> uploadPfp({
    required int userId,
    required File imageFile,
    http.Client? client,
  }) async {
    // MultipartRequest currently requires the real http.Client for send(); if a MockClient is used in tests,
    // tests should stub/override upload behavior or use a http.IOClient/Mocking approach that supports Multipart.
    final uri = Uri.parse('$_base/user/$userId/pfp');
    final request = http.MultipartRequest('POST', uri);

    final mimeTypeSplitted =
        lookupMimeType(imageFile.path)?.split('/') ?? ['image', 'png'];
    final multipartFile = await http.MultipartFile.fromPath(
      'pfp',
      imageFile.path,
      contentType: MediaType(mimeTypeSplitted[0], mimeTypeSplitted[1]),
    );
    request.files.add(multipartFile);

    // Use provided client if it has send, otherwise fallback to default new Client()
    final http.Client c = client ?? http.Client();
    try {
      final streamed = await c.send(request);
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'Upload failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  /// Password reset request (sends email link). Tries server; on failure returns mock success.
  static Future<Map<String, dynamic>> passwordResetRequest({
    required String email,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/auth/password-reset-request');
    try {
      final res = await c.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'Password reset request failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      // Mock fallback: simulate success and show "email content" in response
      final mockToken = _randomDigits(6);
      return {
        'ok': true,
        'data': {
          'mock': true,
          'message': 'Mock reset email would be sent',
          'reset_code': mockToken,
          'info': 'Use this code in-app or implement proper backend endpoint at /auth/password-reset-request'
        }
      };
    }
  }

  /// Request MFA OTP (backend should send SMS/Email/Push). Mock fallback returns the otp in response.
  static Future<Map<String, dynamic>> requestMfaOtp({
    required int userId,
    required String method, // 'email' or 'sms' etc.
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/auth/mfa/request');
    try {
      final res = await c.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'method': method}),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'MFA request failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      final otp = _randomDigits(6);
      return {
        'ok': true,
        'data': {'mock': true, 'otp': otp, 'message': 'Mock OTP generated'}
      };
    }
  }

  /// Verify MFA OTP against backend. Mock checks correctness from provided expectedOtp (used in UI flow).
  static Future<Map<String, dynamic>> verifyMfaOtp({
    required int userId,
    required String code,
    String? expectedOtpForMock, // used only for local mock verification
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/auth/mfa/verify');
    try {
      final res = await c.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'code': code}),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        return {'ok': true, 'data': body};
      }
      final msg = body['error']?.toString() ?? 'MFA verification failed';
      return {'ok': false, 'error': msg};
    } catch (e) {
      // Mock verify
      if (expectedOtpForMock != null && code == expectedOtpForMock) {
        return {'ok': true, 'data': {'mock': true, 'message': 'OTP verified (mock)'}};
      }
      return {'ok': false, 'error': 'Invalid OTP (mock) or network error: $e'};
    }
  }

  static String _randomDigits(int length) {
    final rnd = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(rnd.nextInt(10));
    }
    return buffer.toString();
  }
}