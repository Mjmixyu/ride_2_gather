import 'package:flutter/material.dart';

// Simple friend and post models (can be replaced with actual data)
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
    Friend(name: "Helena Hills", online: true, avatarUrl: ""),
    Friend(name: "Helena Hills", online: true, avatarUrl: ""),
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
      author: "Daniel",
      group: "Group Name",
      text: "",
      likes: 0,
      comments: 0,
      timeAgo: "2 hrs ago",
    ),
    FriendPost(
      imageUrl: "https://images.unsplash.com/photo-1465101046530-73398c7f28ca",
      author: "Daniel",
      group: "Group Name",
      text: "",
      likes: 0,
      comments: 0,
      timeAgo: "2 hrs ago",
    ),
  ];

  String searchQuery = "";

  void openChat(Friend friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(friend: friend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Friend> filteredFriends = friends
        .where((f) => f.name.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return ListView(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'search user ...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              fillColor: Colors.grey.shade100,
              filled: true,
            ),
            onChanged: (val) => setState(() => searchQuery = val),
          ),
        ),
        // Friends List
        ...filteredFriends.map((friend) => ListTile(
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade300,
            child: Icon(Icons.person, size: 28, color: Colors.white),
          ),
          title: Text(friend.name, style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(friend.online ? "Active 11m ago" : "Offline", style: TextStyle(fontSize: 12)),
          trailing: IconButton(
            icon: Icon(Icons.chat_bubble_outline),
            onPressed: () => openChat(friend),
          ),
          onTap: () => openChat(friend),
        )),
        // Friends' Posts Images (horizontal scroll)
        Padding(
          padding: const EdgeInsets.only(left: 12.0, top: 12, bottom: 4),
          child: Text("(shows user friends latest posts)", style: TextStyle(fontSize: 13, color: Colors.grey)),
        ),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: posts
                .map((p) => Container(
              margin: EdgeInsets.symmetric(horizontal: 6),
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(p.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ))
                .toList(),
          ),
        ),
        // Detailed Post Card (Instagram style)
        Card(
          margin: EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurpleAccent,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${posts[0].author} in ${posts[0].group}",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(posts[0].timeAgo, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                SizedBox(height: 10),
                Text(posts[0].text),
                SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 18),
                    SizedBox(width: 4),
                    Text("${posts[0].likes} likes"),
                    SizedBox(width: 12),
                    Icon(Icons.comment_outlined, size: 18),
                    SizedBox(width: 4),
                    Text("${posts[0].comments} comments"),
                    Spacer(),
                    Icon(Icons.notifications_none),
                    SizedBox(width: 6),
                    Icon(Icons.more_horiz),
                  ],
                )
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

// Chat page popup
class ChatPage extends StatefulWidget {
  final Friend friend;
  const ChatPage({super.key, required this.friend});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> messages = [
    {"text": "This is the main chat template", "isMe": true, "time": "Nov 30, 2023, 9:41 AM"},
    {"text": "Oh?", "isMe": false},
    {"text": "Cool", "isMe": false},
    {"text": "How does it work?", "isMe": false},
    {"text": "You just edit any text to type in the conversation you want to show, and delete any bubbles you don't want to use", "isMe": true},
    {"text": "Boom!", "isMe": true},
    {"text": "Hmmm", "isMe": false},
    {"text": "I think I get it", "isMe": false},
    {"text": "Will head to the Help Center if I have more questions tho", "isMe": false},
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, color: Colors.white),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friend.name, style: TextStyle(fontSize: 16)),
                Text("Active 11m ago", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isMe = msg["isMe"];
                return Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    if (msg["time"] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(msg["time"], style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 2),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.black : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        msg["text"],
                        style: TextStyle(color: isMe ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      setState(() {
                        messages.add({"text": _controller.text, "isMe": true});
                        _controller.clear();
                      });
                    }
                  },
                ),
                IconButton(icon: Icon(Icons.attach_file), onPressed: () {}),
                IconButton(icon: Icon(Icons.camera_alt), onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}