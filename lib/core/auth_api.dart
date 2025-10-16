import 'dart:convert';
import 'package:http/http.dart' as http;

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
}