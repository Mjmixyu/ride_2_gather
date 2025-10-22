import 'package:flutter_test/flutter_test.dart';
String? mapBikeNameToAsset(String? displayName, Map<String, String> map) {
  if (displayName == null) return null;
  return map[displayName];
}
void main() {
  test('Bike displayName wird korrekt auf Asset gemappt', () {
    final map = {
      'Yamaha R7': 'assets/bikes/yamahaR7',
      'Kawasaki ZX4R': 'assets/bikes/kawasakiZX4R',
    };
    expect(mapBikeNameToAsset('Yamaha R7', map), 'assets/bikes/yamahaR7');
    expect(mapBikeNameToAsset('Unknown', map), isNull);
  });
}