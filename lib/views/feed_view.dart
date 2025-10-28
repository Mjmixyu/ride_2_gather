import 'dart:io';

import 'package:flutter/material.dart';
import '../core/auth_api.dart';
import '../services/post_repository.dart';
import '../models/post.dart';
import '../theme/auth_theme.dart';
import 'post_viewer.dart';

class FeedView extends StatefulWidget {
  final String username; // logged-in username
  final VoidCallback onProfileTap;

  const FeedView({super.key, required this.username, required this.onProfileTap});

  @override
  State<FeedView> createState() => _FeedViewState();
}

class _FeedViewState extends State<FeedView> {
  final PageController _pageController = PageController(viewportFraction: 0.78);

  // Keep a single featured news item (title + excerpt) shown in content
  final List<Map<String, String>> _news = [
    {
      "title": "title news",
      "excerpt": "some really interesting stuff that's happening rn",
    }
  ];

  List<Post> _posts = [];
  List<Post> _userImagePosts = [];
  List<Post> _textPosts = [];

  // Cache of username -> pfpUrl (null = not yet fetched, empty string = no pfp)
  final Map<String, String?> _pfpCache = {};

  @override
  void initState() {
    super.initState();
    PostRepository.instance.addListener(_onRepoUpdated);
    _refreshFromRepo();

    // Ensure we have the logged-in user's pfp for the top-right profile button
    _fetchAndCachePfp(widget.username);
  }

  Future<void> _fetchAndCachePfp(String username) async {
    if (username.isEmpty) return;
    // avoid duplicate requests
    if (_pfpCache.containsKey(username)) return;

    // mark as fetching
    _pfpCache[username] = null;
    try {
      final res = await AuthApi.getUserByUsername(username);
      if (res['ok'] == true && res['data'] != null) {
        final pfp = (res['data']['pfp'] ?? '') as String;
        _pfpCache[username] = pfp.isNotEmpty ? pfp : '';
      } else {
        _pfpCache[username] = '';
      }
    } catch (_) {
      _pfpCache[username] = '';
    }
    if (mounted) setState(() {});
  }

  void _refreshFromRepo() {
    final all = PostRepository.instance.posts;
    _posts = all;

    // carousel: recent image posts from the currently signed-in user
    _userImagePosts = all
        .where((p) => p.author == widget.username && p.mediaPath != null && p.mediaType == 'image')
        .toList();
    _userImagePosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // text posts: those without media (or explicitly text) — newest first
    _textPosts = all
        .where((p) => (p.mediaPath == null || p.mediaType == null || p.mediaType == 'text'))
        .toList();
    _textPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _onRepoUpdated() {
    if (mounted) setState(_refreshFromRepo);
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

  Widget _avatarFor(String username, {double radius = 20}) {
    // If we haven't fetched pfp yet, start fetch (fire-and-forget)
    if (!_pfpCache.containsKey(username)) {
      _fetchAndCachePfp(username);
      // show placeholder until we have result
      return CircleAvatar(radius: radius, child: const Icon(Icons.person_outline));
    }

    final val = _pfpCache[username];
    if (val == null) {
      // fetching in progress -> placeholder
      return CircleAvatar(radius: radius, child: const Icon(Icons.person_outline));
    }

    if (val.isNotEmpty) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(val));
    }

    // empty string => no pfp -> fallback avatar
    return CircleAvatar(radius: radius, child: const Icon(Icons.person_outline));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // removed bottomNavigationBar as requested previously; keep news in-content
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // small bottom padding to avoid overlapping by navigation controls
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Title Row: show logged-in user's pfp on the right (routing uses onProfileTap)
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
                        child: _avatarFor(widget.username, radius: 18),
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

                // Middle messages list — fixed-height scrollable area that shows up to ~3 items at once.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: _buildScrollableTextPosts(),
                ),

                const SizedBox(height: 12),

                // Keep the single featured news card (title + excerpt) in content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _news.map((item) {
                      final title = item['title'] ?? 'No title';
                      final excerpt = item['excerpt'] ?? '';
                      return InkWell(
                        onTap: () {
                          // simple feedback — you can open a details page or link here
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(title)));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.03)),
                          ),
                          child: Row(
                            children: [
                              // left tile with text "News" to replace an image
                              Container(
                                width: size.width * 0.36,
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade300.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'News',
                                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 6),
                                    Text(excerpt, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
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

                const SizedBox(height: 36), // spacing before bottom of page
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableTextPosts() {
    if (_textPosts.isEmpty) {
      return Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            leading: _avatarFor(widget.username),
            title: const Text('No recent messages', style: TextStyle(color: Colors.white)),
            subtitle: const Text("There are no text posts yet", style: TextStyle(color: Colors.white70)),
            onTap: () {},
          ),
          const Divider(height: 1, color: Colors.white10),
        ],
      );
    }

    // Approximate ListTile height; adjust if your theme changes.
    const double itemHeight = 72.0;
    final int visibleCount = _textPosts.length < 3 ? _textPosts.length : 3;
    final double height = (visibleCount * itemHeight) + 2.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          physics: const ClampingScrollPhysics(),
          itemCount: _textPosts.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
          itemBuilder: (context, index) {
            final post = _textPosts[index];

            // Ensure we attempt to fetch the author's pfp if not already cached.
            if (!_pfpCache.containsKey(post.author)) {
              _fetchAndCachePfp(post.author);
            }

            return SizedBox(
              height: itemHeight,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                leading: _avatarFor(post.author),
                title: Text(post.text, style: const TextStyle(color: Colors.white)),
                subtitle: Text('${post.author} • ${_formatTimeAgo(post.createdAt)}', style: const TextStyle(color: Colors.white70)),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(post.author),
                      content: Text(post.text),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCarousel(Size size) {
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