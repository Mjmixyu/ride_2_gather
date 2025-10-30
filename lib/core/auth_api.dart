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
class AuthApi {
  static const String _base = 'http://10.0.2.2:3000';

  /// Sends a signup request to the server and returns the parsed response.
  ///
  /// @param email The new user's email address.
  /// @param username The desired username.
  /// @param password The desired password.
  /// @param countryCode Optional country code string.
  /// @return A map with 'ok' true and 'data' on success, or 'ok' false and 'error' message on failure.
  static Future<Map<String, dynamic>> signup({
    required String email,
    required String username,
    required String password,
    String countryCode = "",
  }) async {
    final uri = Uri.parse('$_base/signup');
    final res = await http.post(
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
  ///
  /// @param identity The username or email used to log in.
  /// @param password The user's password.
  /// @return A map with 'ok' true and 'data' on success, or 'ok' false and 'error' message on failure.
  static Future<Map<String, dynamic>> login({
    required String identity,
    required String password,
  }) async {
    final uri = Uri.parse('$_base/login');
    final res = await http.post(
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
  ///
  /// This may include additional information such as the user's chosen bike details.
  ///
  /// @param username The username to look up.
  /// @return A map with 'ok' true and 'data' on success, or 'ok' false and 'error' message on failure.
  static Future<Map<String, dynamic>> getUserByUsername(String username) async {
    final uri = Uri.parse('$_base/user/$username');
    final res = await http.get(uri);
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'data': body};
    }
    final msg = body['error']?.toString() ?? 'Get user failed';
    return {'ok': false, 'error': msg};
  }

  /// Updates the given user's settings such as bio and selected bike name.
  ///
  /// Providing a null or empty [bikeName] will clear any existing bike selection.
  ///
  /// @param userId The numeric ID of the user to update.
  /// @param bio Optional bio text to set.
  /// @param bikeName Optional bike name to set or clear.
  /// @return A map with 'ok' true and 'data' on success, or 'ok' false and 'error' message on failure.
  static Future<Map<String, dynamic>> updateUserSettings({
    required int userId,
    String? bio,
    String? bikeName,
  }) async {
    final uri = Uri.parse('$_base/user/$userId');
    final res = await http.patch(
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
  ///
  /// The server expects the file field to be named 'pfp'. The function sets
  /// the content type based on the file mime type when possible.
  ///
  /// @param userId The numeric ID of the user whose profile picture is being uploaded.
  /// @param imageFile The image File to upload.
  /// @return A map with 'ok' true and 'data' on success, or 'ok' false and 'error' message on failure.
  static Future<Map<String, dynamic>> uploadPfp({
    required int userId,
    required File imageFile,
  }) async {
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

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
    if (res.statusCode == 200) {
      return {'ok': true, 'data': body};
    }
    final msg = body['error']?.toString() ?? 'Upload failed';
    return {'ok': false, 'error': msg};
  }
}