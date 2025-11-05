/**
 * friends_chat_view.dart
 *
 * Loads friends from the server (AuthApi.listUsers) and shows the latest text
 * posts from PostRepository. Chat screen remains mocked/local.
 *
 * Fixes applied:
 * - Removed unused import of shared_preferences that was causing a lint warning.
 * - Fixed the height calculation for the Latest text posts SizedBox so it produces
 *   a double (avoids "The argument type 'num' can't be assigned to the parameter
 *   type 'double?'" error).
 * - Kept behavior otherwise unchanged.
 */

import 'package:flutter/material.dart';
import '../theme/auth_theme.dart';
import '../core/auth_api.dart';
import '../services/post_repository.dart';
import '../models/post.dart';

class Friend {
  final String name;
  final bool online;
  final String avatarUrl;
  final int? id;
  Friend({required this.name, required this.online, required this.avatarUrl, this.id});
}

class FriendsChatView extends StatefulWidget {
  const FriendsChatView({super.key});

  @override
  State<FriendsChatView> createState() => _FriendsChatViewState();
}

class _FriendsChatViewState extends State<FriendsChatView> {
  List<Friend> _friends = [];
  String _searchQuery = "";
  bool _loadingFriends = true;

  List<Post> _latestTextPosts = [];
  final Map<String, String?> _pfpCache = {};

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _refreshPostsFromRepo();
    PostRepository.instance.addListener(_refreshPostsFromRepo);
  }

  @override
  void dispose() {
    PostRepository.instance.removeListener(_refreshPostsFromRepo);
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final res = await AuthApi.listUsers();
      if (res['ok'] == true && res['data'] is List) {
        final List data = res['data'] as List;
        _friends = data.map((u) {
          final username = (u['username'] ?? '').toString();
          final pfp = (u['pfp'] ?? '').toString();
          final lastOnline = u['lastOnline'];
          final online = lastOnline != null;
          final id = (u['id'] as num?)?.toInt();
          _pfpCache[username] = pfp.isNotEmpty ? pfp : '';
          return Friend(name: username, online: online, avatarUrl: pfp, id: id);
        }).toList();
      } else {
        // fallback small static list if server call fails
        _friends = [
          Friend(name: "alice", online: true, avatarUrl: "", id: null),
          Friend(name: "bob", online: false, avatarUrl: "", id: null),
        ];
      }
    } catch (_) {
      _friends = [
        Friend(name: "alice", online: true, avatarUrl: "", id: null),
        Friend(name: "bob", online: false, avatarUrl: "", id: null),
      ];
    } finally {
      if (mounted) setState(() => _loadingFriends = false);
    }
  }

  void _refreshPostsFromRepo() {
    final all = PostRepository.instance.posts;
    _latestTextPosts = all
        .where((p) => p.mediaPath == null || p.mediaPath!.isEmpty || p.mediaType == 'text')
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_latestTextPosts.length > 6) _latestTextPosts = _latestTextPosts.sublist(0, 6);
    if (mounted) setState(() {});
  }

  void _openChat(Friend friend) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(friend: friend)));
  }

  Widget _avatarFor(String username, {double radius = 20}) {
    if (!_pfpCache.containsKey(username)) {
      _pfpCache[username] = null;
      AuthApi.getUserByUsername(username).then((res) {
        if (res['ok'] == true && res['data'] != null) {
          final pfp = (res['data']['pfp'] ?? '').toString();
          _pfpCache[username] = pfp.isNotEmpty ? pfp : '';
          if (mounted) setState(() {});
        } else {
          _pfpCache[username] = '';
          if (mounted) setState(() {});
        }
      }).catchError((_) {
        _pfpCache[username] = '';
        if (mounted) setState(() {});
      });
      return CircleAvatar(radius: radius, child: const Icon(Icons.person_outline));
    }
    final val = _pfpCache[username];
    if (val == null) return CircleAvatar(radius: radius, child: const Icon(Icons.person_outline));
    if (val.isNotEmpty) return CircleAvatar(radius: radius, backgroundImage: NetworkImage(val));
    return CircleAvatar(radius: radius, child: const Icon(Icons.person_outline));
  }

  String _formatTimeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 2) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inDays < 1) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _friends.where((f) => f.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    // compute a double height safely (avoid num -> double error)
    final double postsBoxHeight = _latestTextPosts.isEmpty
        ? 80.0
        : ((_latestTextPosts.length * 72.0).clamp(80.0, 300.0)).toDouble();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AuthTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: Colors.black54, child: const Icon(Icons.people, color: Colors.white70)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("Friends", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _loadFriends),
                    IconButton(icon: const Icon(Icons.person_add_alt, color: Colors.white70), onPressed: () {}),
                  ],
                ),
              ),

              // Card with search + friends list + latest text posts
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 18, offset: const Offset(0, 8))],
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Column(
                      children: [
                        // Search
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search, color: Colors.white70),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          onChanged: (val) => setState(() => _searchQuery = val),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: const InputDecoration(
                                            hintText: 'Search friends',
                                            hintStyle: TextStyle(color: Colors.white70),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(color: Colors.white12, height: 1),

                        // Friends list
                        Expanded(
                          flex: 3,
                          child: _loadingFriends
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                            itemBuilder: (_, i) {
                              final friend = filtered[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey.shade800,
                                  backgroundImage: friend.avatarUrl.isNotEmpty ? NetworkImage(friend.avatarUrl) : null,
                                  child: friend.avatarUrl.isEmpty ? const Icon(Icons.person, size: 28, color: Colors.white70) : null,
                                ),
                                title: Text(friend.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                subtitle: Text(friend.online ? "Active recently" : "Offline", style: const TextStyle(color: Colors.white70)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                                  onPressed: () => _openChat(friend),
                                ),
                                onTap: () => _openChat(friend),
                              );
                            },
                          ),
                        ),

                        const Divider(color: Colors.white12, height: 1),

                        // Latest text posts
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Latest text posts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: postsBoxHeight,
                                child: _latestTextPosts.isEmpty
                                    ? Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('No recent text posts', style: TextStyle(color: Colors.white70)),
                                )
                                    : ListView.separated(
                                  physics: const ClampingScrollPhysics(),
                                  itemCount: _latestTextPosts.length,
                                  separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                                  itemBuilder: (context, idx) {
                                    final p = _latestTextPosts[idx];
                                    if (!_pfpCache.containsKey(p.author)) _pfpCache[p.author] = null;
                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      leading: _avatarFor(p.author, radius: 20),
                                      title: Text(p.text, style: const TextStyle(color: Colors.white), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      subtitle: Text('${p.author} • ${_formatTimeAgo(p.createdAt)}', style: const TextStyle(color: Colors.white70)),
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(p.author),
                                            content: Text(p.text),
                                            actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat screen widget (mocked/local messages)
class ChatScreen extends StatefulWidget {
  final Friend friend;
  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> messages = [
    {"text": "Hey, you free for a ride?", "isMe": false},
    {"text": "Yes! When?", "isMe": true},
    {"text": "This Sunday morning?", "isMe": false},
  ];

  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      messages.add({"text": _ctrl.text.trim(), "isMe": true});
      _ctrl.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 100, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(backgroundColor: Colors.grey.shade800, child: const Icon(Icons.person, color: Colors.white)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.friend.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
              const Text("Active recently", style: TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AuthTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg["isMe"] as bool;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.blueAccent : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(msg["text"], style: const TextStyle(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ),

              // Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () {}),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Write a message...', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.emoji_emotions, color: Colors.white70), onPressed: () {}),
                      GestureDetector(
                        onTap: _send,
                        child: Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle), child: const Icon(Icons.send, color: Colors.white, size: 18)),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}