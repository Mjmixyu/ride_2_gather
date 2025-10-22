import 'package:flutter/material.dart';
import '../theme/auth_theme.dart';

/// Simple friend and post models (kept from original)
class Friend {
  final String name;
  final bool online;
  final String avatarUrl;
  Friend({required this.name, required this.online, required this.avatarUrl});
}

class FriendPost {
  final String imageUrl;
  final String author;
  final String group;
  final String text;
  final int likes;
  final int comments;
  final String timeAgo;
  FriendPost({
    required this.imageUrl,
    required this.author,
    required this.group,
    required this.text,
    required this.likes,
    required this.comments,
    required this.timeAgo,
  });
}

class FriendsChatView extends StatefulWidget {
  const FriendsChatView({super.key});

  @override
  State<FriendsChatView> createState() => _FriendsChatViewState();
}

class _FriendsChatViewState extends State<FriendsChatView> {
  List<Friend> friends = [
    Friend(name: "Helena Hills", online: true, avatarUrl: ""),
    Friend(name: "Daniel Smith", online: false, avatarUrl: ""),
    Friend(name: "Ava Reed", online: true, avatarUrl: ""),
  ];

  List<FriendPost> posts = [
    FriendPost(
      imageUrl: "https://placekitten.com/200/200",
      author: "Daniel",
      group: "Group Name",
      text: "Body text for a post. Since it's a social app, sometimes it's a hot take, and sometimes it's a question.",
      likes: 6,
      comments: 18,
      timeAgo: "2 hrs ago",
    ),
    FriendPost(
      imageUrl: "https://images.unsplash.com/photo-1518717758536-85ae29035b6d",
      author: "Helena",
      group: "Riders",
      text: "Check out this ride!",
      likes: 14,
      comments: 4,
      timeAgo: "4 hrs ago",
    ),
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // Use the shared auth/login gradient so the page background matches other pages
    return Scaffold(
      // entire screen uses the app's auth gradient so it aligns visually with other pages
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header: simple title row (keeps existing icons but styled for the gradient)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.black54,
                      child: const Icon(Icons.people, color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Friends",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.white70),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt, color: Colors.white70),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              // Main rounded card container to match the other pages' dark translucent cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Column(
                      children: [
                        // Search / quick actions row inside the card, styled as pill input
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.03),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search, color: Colors.white70),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          onChanged: (val) => setState(() => searchQuery = val),
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
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.06),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {},
                                child: const Text('New'),
                              )
                            ],
                          ),
                        ),

                        const Divider(color: Colors.white12, height: 1),

                        // Friends list
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: friends.where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase())).length,
                            separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                            itemBuilder: (context, index) {
                              final filtered = friends.where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                              final friend = filtered[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.grey.shade800,
                                  child: const Icon(Icons.person, size: 28, color: Colors.white70),
                                ),
                                title: Text(friend.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                subtitle: Text(friend.online ? "Active recently" : "Offline", style: const TextStyle(color: Colors.white70)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70),
                                  onPressed: () => openChat(friend),
                                ),
                                onTap: () => openChat(friend),
                              );
                            },
                          ),
                        ),

                        const Divider(color: Colors.white12, height: 1),

                        // friends' latest posts horizontal (styled to match the card)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Friends\' latest posts', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: posts.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, i) {
                                    final p = posts[i];
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(p.imageUrl, width: 160, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
                                        return Container(width: 160, height: 120, color: Colors.grey.shade800, child: const Icon(Icons.broken_image, color: Colors.white70));
                                      }),
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

  void openChat(Friend friend) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(friend: friend)));
  }
}

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

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() {
      messages.add({"text": _ctrl.text.trim(), "isMe": true});
      _ctrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Chat screen uses the same gradient background to match other pages
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friend.name, style: const TextStyle(fontSize: 16, color: Colors.white)),
                const Text("Active recently", style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.call, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AuthTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  reverse: false,
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

              // input area placed in a rounded card so it matches other pages
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: () {}),
                      Expanded(
                        child: TextField(
                          controller: _ctrl,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Write a message...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.emoji_emotions, color: Colors.white70), onPressed: () {}),
                      GestureDetector(
                        onTap: _send,
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.send, color: Colors.white, size: 18),
                        ),
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