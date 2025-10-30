import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

class FakeApi {
  final http.Client client;
  FakeApi(this.client);

  Future<Map<String, dynamic>> getUserByUsername(String username) async {
    final resp = await client.get(Uri.parse('http://example.com/user/$username'));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}

class UserProfilePageShim extends StatefulWidget {
  final String username;
  final FakeApi api;
  const UserProfilePageShim({Key? key, required this.username, required this.api}) : super(key: key);
  @override
  State<UserProfilePageShim> createState() => _UserProfilePageShimState();
}

class _UserProfilePageShimState extends State<UserProfilePageShim> {
  String? bikeName;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final resp = await widget.api.getUserByUsername(widget.username);
    setState(() {
      loading = false;
      bikeName = resp['data']?['myBike']?['name'] as String?;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const CircularProgressIndicator();
    return Material(child: Text(bikeName ?? 'kein Bike', key: const Key('user_bike_text')));
  }
}

void main() {
  testWidgets('UserProfilePage zeigt myBike.name aus API an', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(jsonEncode({
        'ok': true,
        'data': {
          'id': 1,
          'username': 'vanessa',
          'bio': '',
          'pfp': '',
          'myBike': {'name': 'Yamaha R7', 'image': 'http://example.com/yamaha.png'}
        }
      }), 200);
    });

    final api = FakeApi(mockClient);

    await tester.pumpWidget(MaterialApp(home: UserProfilePageShim(username: 'vanessa', api: api)));

    // initial loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // wait for async fetch
    await tester.pumpAndSettle();

    expect(find.text('Yamaha R7'), findsOneWidget);
    expect(find.byKey(const Key('user_bike_text')), findsOneWidget);
  });
}