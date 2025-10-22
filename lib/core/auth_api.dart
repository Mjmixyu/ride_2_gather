import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class AuthApi {
  static const String _base = 'http://10.0.2.2:3000';

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

  // LOGIN: identity = username OR email
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

  // Fetch user by username (includes myBike info if set)
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

  // Update user settings (bio & bike_name). bikeName may be null/empty to clear selection.
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

  // Upload profile picture (multipart/form-data) to API.
  // Field name on server must be 'pfp'.
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
