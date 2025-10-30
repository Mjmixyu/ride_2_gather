import 'package:flutter_test/flutter_test.dart';

String? mapBikeNameToAsset(String? displayName, Map<String, String> map) {
  if (displayName == null) return null;
  return map[displayName];
}

void main() {
  group('Modul B - Bike', () {
    test('Bike displayName wird korrekt auf Asset gemappt', () {
      final map = {
        'Yamaha R7': 'assets/images/yamahaR7',
        'Kawasaki ZX4R': 'assets/images/kawasakiZX4R',
        'Honda CBR 605 R': 'assets/images/hondaCBR650R',
      };

      expect(mapBikeNameToAsset('Yamaha R7', map), 'assets/images/yamahaR7');
      expect(mapBikeNameToAsset('Kawasaki ZX4R', map), 'assets/images/kawasakiZX4R');
      expect(mapBikeNameToAsset('Honda CBR 605 R', map), 'assets/images/hondaCBR650R');

      expect(mapBikeNameToAsset('Unknown', map), isNull);
      expect(mapBikeNameToAsset(null, map), isNull);
    });
  });
}