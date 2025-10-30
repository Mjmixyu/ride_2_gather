import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ride2gather/core/auth_api.dart';

void main() {
  group('Modul C - UserSettings', () {
    test('Entfernen der Bike-Auswahl sendet bike_name: null', () async {
      Map<String, dynamic>? sentBody;

      final mockClient = MockClient((request) async {
        sentBody = jsonDecode(request.body) as Map<String, dynamic>?;
        return http.Response(jsonEncode({'ok': true, 'data': {}}), 200);
      });

      final result = await AuthApi.updateUserSettings(userId: 1, bio: null, bikeName: null, client: mockClient);

      expect(result['ok'], true);
      expect(sentBody, isNotNull);
      expect(sentBody!['bike_name'], isNull);
    });
  });
}