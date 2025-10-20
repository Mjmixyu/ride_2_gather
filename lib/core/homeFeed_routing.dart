import 'package:flutter/material.dart';
import '../views/add_post_view.dart';
import '../views/feed_view.dart';
import '../views/firends_chat_view.dart';
import '../views/userProfile_view.dart';
import '../views/map_view.dart';

class HomeFeed extends StatefulWidget {
  final String username;
  final int userId;

  const HomeFeed({Key? key, required this.username, required this.userId}) : super(key: key);

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedView(onProfileTap: _onProfileNav, username: widget.username),
      MapView(),
      AddPostView(),
      FriendsChatView(),
      // Pass viewerUsername so UserProfilePage can know whether viewer == profile owner
      UserProfilePage(
        username: widget.username,
        bio: '',
        bike: '',
        pfpUrl: '',
        viewerUsername: widget.username,
        userId: widget.userId,
      ),
    ];
  }

  void _onProfileNav() {
    setState(() {
      _selectedIndex = 4; // Profile tab index
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "HomeFeed"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: "Add Post"),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Friends/Chat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "UserProfile"),
        ],
      ),
    );
  }
}