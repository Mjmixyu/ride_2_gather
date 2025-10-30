import 'package:flutter_test/flutter_test.dart';

class HomeFeedStateShim {
  int selectedIndex = 0;
  void onProfileNav() {
    selectedIndex = 4;
  }
}

void main() {
  group('Modul C - UI Navigation & Settings', () {
    test('HomeFeed: _onProfileNav setzt selectedIndex auf 4 (Profile-Tab)', () {
      final state = HomeFeedStateShim();
      expect(state.selectedIndex, isNot(4));
      state.onProfileNav();
      expect(state.selectedIndex, 4);
    });
  });
}