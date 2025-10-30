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
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

/// A collection of static methods to call the authentication-related server endpoints.
///
/// NOTE: Methods now accept an optional http.Client? client parameter (default null).
/// This keeps production behavior unchanged while allowing tests to inject a MockClient.
class AuthApi {
  static const String _base = 'http://10.0.2.2:3000';

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
  }

  /// Sends a login request using either username or email as the identity.
  static Future<Map<String, dynamic>> login({
    required String identity,
    required String password,
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/login');
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
  }

  /// Retrieves a user's public profile by username.
  static Future<Map<String, dynamic>> getUserByUsername(
    String username, {
    http.Client? client,
  }) async {
    final c = client ?? http.Client();
    final uri = Uri.parse('$_base/user/$username');
    final res = await c.get(uri);
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'data': body};
    }
    final msg = body['error']?.toString() ?? 'Get user failed';
    return {'ok': false, 'error': msg};
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
    final streamed = await c.send(request);
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'data': body};
    }
    final msg = body['error']?.toString() ?? 'Upload failed';
    return {'ok': false, 'error': msg};
  }
}
