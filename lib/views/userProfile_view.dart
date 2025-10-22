import 'package:flutter/material.dart';
import 'user_settings_view.dart';
import '../theme/auth_theme.dart';
import '../core/auth_api.dart';
import '../models/bike.dart';
import '../services/post_repository.dart';
import '../models/post.dart';
import 'dart:io';

class UserProfilePage extends StatefulWidget {
  final String username;
  final String bio;
  final String bike;
  final String pfpUrl;
  final String? viewerUsername; // who's viewing the profile (nullable)
  final int userId;

  const UserProfilePage({
    Key? key,
    required this.username,
    required this.bio,
    required this.bike,
    required this.pfpUrl,
    this.viewerUsername,
    required this.userId,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String _bio = '';
  String _bike = '';
  String _pfp = '';
  bool _loading = true;

  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _bio = widget.bio;
    _bike = widget.bike;
    _pfp = widget.pfpUrl;
    _fetchUser();
    _posts = PostRepository.instance.posts.where((p) => p.author == widget.username).toList();
    PostRepository.instance.addListener(_repoUpdated);
  }

  @override
  void dispose() {
    PostRepository.instance.removeListener(_repoUpdated);
    super.dispose();
  }

  void _repoUpdated() {
    if (mounted) {
      setState(() {
        _posts = PostRepository.instance.posts.where((p) => p.author == widget.username).toList();
      });
    }
  }

  Future<void> _fetchUser() async {
    setState(() => _loading = true);
    try {
      final res = await AuthApi.getUserByUsername(widget.username);
      if (res['ok'] == true) {
        final data = res['data'];
        setState(() {
          _bio = (data['bio'] ?? '') as String;
          _pfp = (data['pfp'] ?? '') as String;
          // myBike may be object or null
          final myBike = data['myBike'];
          if (myBike != null && myBike['name'] != null) {
            _bike = myBike['name'] as String;
          } else {
            _bike = '';
          }
        });
      } else {
        // show error (optional)
      }
    } catch (e) {
      // ignore for now
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Determine whether the current viewer is the profile owner
  bool get isOwnProfile => widget.viewerUsername != null && widget.viewerUsername == widget.username;

  @override
  Widget build(BuildContext context) {
    final mediaTopHeight = 300.0;

    return Scaffold(
      // keep scaffold's background as gradient to match auth screens
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Top profile banner implemented as a Stack so the settings button can be anchored
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: mediaTopHeight,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Background image or solid color
                      Positioned.fill(
                        child: _pfp.isNotEmpty
                            ? Image.network(
                          _pfp,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: mediaTopHeight,
                          alignment: Alignment.topCenter,
                        )
                            : Container(
                          color: const Color(0xFF000080),
                          child: const Center(
                            child: Icon(Icons.person, size: 96, color: Colors.white70),
                          ),
                        ),
                      ),

                      // Subtle gradient overlay for readability (covers image smoothly)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.06),
                                Colors.black.withOpacity(0.28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main content positioned below the top banner (the top of this container slightly overlaps the image to create a smooth transition)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Reserve space so the top image remains visible to the very top.
                    SizedBox(height: mediaTopHeight - 102),

                    // Dark rounded content area that matches auth design
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // Username + follow button (follow only when viewing others)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Username column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "@${widget.username}",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        _loading
                                            ? const Text('Loading...', style: TextStyle(color: Colors.white70, fontSize: 13))
                                            : Text(
                                          _bio,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Right side: Follow button only if viewing other profiles
                                  if (!isOwnProfile)
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        style: AuthTheme.mainButtonStyle.copyWith(
                                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: const Text("Follow", style: TextStyle(fontSize: 14)),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Bike placeholder
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0),
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // If a known bike from enum exists, show its asset; otherwise fallback to an icon and text
                                        if (_bike.isNotEmpty)
                                          Builder(builder: (context) {
                                            final match = allBikes.where((b) => b.displayName == _bike);
                                            if (match.isNotEmpty) {
                                              final b = match.first;
                                              return Column(
                                                children: [
                                                  Image.asset('${b.assetPath}.png', height: 130, fit: BoxFit.contain, errorBuilder: (_, __, ___) {
                                                    return const Icon(Icons.motorcycle, size: 80, color: Colors.black);
                                                  }),
                                                  const SizedBox(height: 8),
                                                  // Text(_bike, style: const TextStyle(fontSize: 14, color: Colors.black)),
                                                ],
                                              );
                                            } else {
                                              return Column(
                                                children: [
                                                  const Icon(Icons.motorcycle, size: 80, color: Colors.black),
                                                  const SizedBox(height: 8),
                                                  Text(_bike, style: const TextStyle(fontSize: 14, color: Colors.black)),
                                                ],
                                              );
                                            }
                                          })
                                        else
                                          Column(
                                            children: const [
                                              Icon(Icons.motorcycle, size: 80, color: Colors.black),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Posts grid - use real posts from the repository
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: _posts.isEmpty
                                    ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.photo_library, size: 64, color: Colors.white70),
                                        SizedBox(height: 12),
                                        Text('No posts yet', style: TextStyle(color: Colors.white70)),
                                      ],
                                    ),
                                  ),
                                )
                                    : GridView.builder(
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                  ),
                                  itemCount: _posts.length,
                                  itemBuilder: (context, index) {
                                    final post = _posts[index];
                                    if (post.mediaPath != null && post.mediaType == "image") {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(File(post.mediaPath!), fit: BoxFit.cover),
                                      );
                                    } else if (post.mediaPath != null && post.mediaType == "video") {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Center(child: Icon(Icons.videocam, color: Colors.white70)),
                                      );
                                    } else {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade400,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.text_snippet, color: Colors.white),
                                      );
                                    }
                                  },
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
            ),

            // Settings button: placed last in the Stack so it's on top and receives taps.
            if (isOwnProfile)
              Positioned(
                // place slightly below the bottom edge of the top image (overlapping the content)
                top: mediaTopHeight - 36,
                right: 16,
                child: Material(
                  // Material used to get proper elevation/shadow and to ensure taps are recognized
                  color: Colors.transparent,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 26,
                      ),
                      tooltip: "User Settings",
                      onPressed: () async {
                        // open settings and refresh after save
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => UserSettingsPage(
                              userId: widget.userId,
                              username: widget.username,
                              bio: _bio,
                              bike: _bike,
                              pfpUrl: _pfp,
                            ),
                          ),
                        );
                        if (result == true) {
                          // user saved changes — refresh displayed data
                          await _fetchUser();
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}