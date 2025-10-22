import 'dart:io';

import 'package:flutter/material.dart';
import '../services/post_repository.dart';
import '../models/post.dart';
import '../theme/auth_theme.dart';
import 'post_viewer.dart';

class FeedView extends StatefulWidget {
  final String username;
  final VoidCallback onProfileTap;

  const FeedView({super.key, required this.username, required this.onProfileTap});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final PageController _pageController = PageController(viewportFraction: 0.78);
  final List<String> _messages = [
    "message text here?",
    "message text here?",
  ];

  final List<Map<String, String>> _news = [
    {
      "title": "title news",
      "excerpt": "some really interesting stuff that's happening rn",
      "thumb": "https://picsum.photos/seed/news1/400/240",
    }
  ];

  List<Post> _posts = [];
  List<Post> _userImagePosts = [];

  @override
  void initState() {
    super.initState();
    PostRepository.instance.addListener(_onRepoUpdated);
    _refreshFromRepo();
  }

  void _refreshFromRepo() {
    final all = PostRepository.instance.posts;
    _posts = all;
    // carousel should show recent image posts from the currently signed-in user
    _userImagePosts = all
        .where((p) => p.author == widget.username && p.mediaPath != null && p.mediaType == 'image')
        .toList();
    // newest first
    _userImagePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _onRepoUpdated() {
    if (mounted) {
      setState(() {
        _refreshFromRepo();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    PostRepository.instance.removeListener(_onRepoUpdated);
    super.dispose();
  }

  double _calculateScale(int index) {
    if (!_pageController.hasClients || _pageController.positions.isEmpty) return 1.0;
    final page = _pageController.page ?? _pageController.initialPage.toDouble();
    final diff = (page - index).abs();
    return (1 - (diff * 0.16)).clamp(0.82, 1.0);
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
    final size = MediaQuery.of(context).size;

    // Keep the original layout exactly, but change only the background to the auth/login gradient.
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Title Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "ride2gather",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      GestureDetector(
                        onTap: widget.onProfileTap,
                        child: const CircleAvatar(child: Icon(Icons.person_outline)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Centered carousel / featured area (large, rounded cards layered)
                SizedBox(
                  height: 180,
                  child: _buildUserCarousel(size),
                ),

                const SizedBox(height: 12),

                // Simple messages list (small avatar + text lines)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: List.generate(_messages.length, (idx) {
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                            title: Text(_messages[idx], style: const TextStyle(color: Colors.white)),
                            subtitle: const Text("short subtitle or metadata", style: TextStyle(color: Colors.white70)),
                            onTap: () {},
                          ),
                          const Divider(height: 1, color: Colors.white10),
                        ],
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 12),

                // News / featured card (image left, text right)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _news.map((item) {
                      return InkWell(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item["thumb"]!,
                                  width: size.width * 0.52,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: size.width * 0.52,
                                    height: 90,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 36),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item["title"] ?? "No title", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Text(item["excerpt"] ?? "", maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // NOTE: posts under the news have been removed (per your request).
                // If you later want to re-enable a posts list under news, re-insert the posts UI here.

                const SizedBox(height: 36), // spacing before bottom nav
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCarousel(Size size) {
    // If user has recent image posts, show them; otherwise show placeholder cards (keeps original layout)
    if (_userImagePosts.isEmpty) {
      return PageView.builder(
        controller: _pageController,
        itemCount: 5,
        itemBuilder: (context, index) {
          final scale = _calculateScale(index);
          return Transform.scale(
            scale: scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _userImagePosts.length,
      itemBuilder: (context, index) {
        final post = _userImagePosts[index];
        final scale = _calculateScale(index);
        return Transform.scale(
          scale: scale,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: GestureDetector(
              onTap: () {
                // navigate to full-screen post viewer starting at this post
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PostViewerPage(posts: _userImagePosts, initialIndex: index),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: post.mediaPath != null
                    ? Image.file(
                  File(post.mediaPath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                )
                    : Container(color: Colors.grey.shade200),
              ),
            ),
          ),
        );
      },
    );
  }
}