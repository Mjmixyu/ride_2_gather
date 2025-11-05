/**
 * chats_api.dart
 *
 * Simple client for chat endpoints:
 *  - getThread(a,b)
 *  - sendMessage(senderId, receiverId, text)
 *  - markRead(userId, fromUserId)
 *  - unreadCounts(userId) => Map<int,int>
 */
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatsApi {
  static const String _base = 'http://10.0.2.2:3000';

  static Future<Map<String, dynamic>> getThread({
    required int userA,
    required int userB,
  }) async {
    try {
      final res = await http.get(Uri.parse('$_base/chats/$userA/$userB'));
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) return {'ok': true, 'data': body['data'] ?? []};
      return {'ok': false, 'error': body['error'] ?? 'Failed to load thread'};
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendMessage({
    required int senderId,
    required int receiverId,
    required String text,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_base/chats'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'senderId': senderId, 'receiverId': receiverId, 'messageTxt': text}),
      );
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 201) return {'ok': true, 'data': body['data']};
      return {'ok': false, 'error': body['error'] ?? 'Failed to send message'};
    } catch (e) {
      return {'ok': false, 'error': 'Network error: $e'};
    }
  }

  static Future<void> markRead({required int userId, required int fromUserId}) async {
    try {
      await http.post(
        Uri.parse('$_base/chats/read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fromUserId': fromUserId}),
      );
    } catch (_) {}
  }

  static Future<Map<int, int>> unreadCounts({required int userId}) async {
    try {
      final res = await http.get(Uri.parse('$_base/chats/unread/$userId'));
      final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);
      if (res.statusCode == 200) {
        final raw = (body['data'] ?? {}) as Map<String, dynamic>;
        return raw.map((k, v) => MapEntry(int.tryParse(k) ?? -1, (v as num?)?.toInt() ?? 0));
      }
    } catch (_) {}
    return {};
  }
}
