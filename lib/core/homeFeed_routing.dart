/**
 * home_feed.dart
 *
 * File-level Dartdoc:
 * Defines the HomeFeed widget which provides the main bottom-tab navigation
 * for the application. It constructs the page list and handles tab switching,
 * including external tab requests forwarded via PostRepository.
 */
import 'package:flutter/material.dart';
import '../views/add_post_view.dart';
import '../views/feed_view.dart';
import '../views/firends_chat_view.dart';
import '../views/userProfile_view.dart';
import '../views/map_view.dart';
import '../services/post_repository.dart';

/// A stateful widget that displays the main app pages with a BottomNavigationBar.
///
/// The widget requires the currently signed-in username and the userId so
/// that pages which need viewer context can be initialized.
class HomeFeed extends StatefulWidget {
  final String username;
  final int userId;

  const HomeFeed({Key? key, required this.username, required this.userId}) : super(key: key);

  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

/// State for HomeFeed that manages the selected tab and page list.
class _HomeFeedState extends State<HomeFeed> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;
  late final VoidCallback _tabListener;

  @override
  void initState() {
    super.initState();
    _pages = [
      FeedView(onProfileTap: _onProfileNav, username: widget.username),
      const MapView(),
      AddPostView(author: widget.username),
      const FriendsChatView(),
      UserProfilePage(
        username: widget.username,
        bio: '',
        bike: '',
        pfpUrl: '',
        viewerUsername: widget.username,
        userId: widget.userId,
      ),
    ];

    /// Sets up a listener for external tab requests from PostRepository.
    /// When a request is present, updates the selected index and clears the request.
    _tabListener = () {
      final req = PostRepository.instance.tabRequest.value;
      if (req != null) {
        setState(() {
          _selectedIndex = req;
        });
        PostRepository.instance.tabRequest.value = null;
      }
    };
    PostRepository.instance.tabRequest.addListener(_tabListener);
  }

  @override
  void dispose() {
    PostRepository.instance.tabRequest.removeListener(_tabListener);
    super.dispose();
  }

  /// Switches view to the profile tab.
  ///
  /// This helper sets the selected tab index to the profile page index.
  void _onProfileNav() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  /// Handler for tap events on the bottom navigation bar.
  ///
  /// @param index The index of the tab that was tapped.
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