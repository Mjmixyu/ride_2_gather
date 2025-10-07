import 'package:flutter/material.dart';
import '../views/feed_view.dart';
import '../views/userProfile_view.dart';

class HomeFeed extends StatefulWidget {
  final String username;

  const HomeFeed({Key? key, required this.username}) : super(key: key);

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  int _selectedIndex = 0;
  bool _showUserProfile = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedView(onProfileTap: _openUserProfile, username: widget.username),
      const Center(child: Text("Map Page", style: TextStyle(fontSize: 24))),
      const Center(child: Text("Chats Page", style: TextStyle(fontSize: 24))),
      const Center(child: Text("Posts Page", style: TextStyle(fontSize: 24))), // legacy
    ];
  }

  //this function calls the openUser and highlights the tab in the bottom nav bar
  void _openUserProfile() {
    setState(() {
      _showUserProfile = true;
      _selectedIndex = 3;
    });
  }

  //this function lets the user return to the home feed once in th user profile
  void _onItemTapped(int index) {
    setState(() {
      if (_showUserProfile && index == 0) {
        _showUserProfile = false;
        _selectedIndex = 0;
        return;
      }

      _selectedIndex = index;
    });
  }

  //this function changes the bottom navbar tab "posts" to "profile" when the user is on his profile
  @override
  Widget build(BuildContext context) {
    final items = _showUserProfile
        ? [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Feed"),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
      const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
      const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
    ]
        : [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
      const BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
      const BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chats"),
      const BottomNavigationBarItem(icon: Icon(Icons.add_a_photo), label: "Post"),
    ];

    return Scaffold(
      body: _showUserProfile
          ? UserProfilePage(username: widget.username)
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Colors.grey,
        items: items,
      ),
    );
  }
}
