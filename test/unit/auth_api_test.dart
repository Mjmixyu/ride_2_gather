import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:ride2gather/core/auth_api.dart';

void main() {
  group('Modul A - Authentication API', () {
    test('login() verarbeitet Erfolg (HTTP 200) korrekt', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'token': 'abc', 'user': {'id': 1, 'username': 'vanessa'}}), 200);
      });

      final result = await AuthApi.login(identity: 'u', password: 'p', client: mockClient);

      expect(result['ok'], true);
      expect(result['data']['token'], 'abc');
      expect(result['data']['user']['username'], 'vanessa');
    });

    test('login() verarbeitet Fehler (HTTP 401) korrekt', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'error': 'Invalid credentials'}), 401);
      });

      final result = await AuthApi.login(identity: 'u', password: 'wrong', client: mockClient);

      expect(result['ok'], false);
      expect(result['error'], 'Invalid credentials');
    });
  });
}