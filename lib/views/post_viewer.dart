/**
 * post_viewer.dart
 *
 * File-level Dartdoc:
 * Page for viewing a list of posts (typically media posts) in a full-screen
 * pager. Shows the media (image or video placeholder) and post metadata such
 * as author, time ago, text, and optional location. Supports swiping between posts.
 */
import 'dart:io';

import 'package:flutter/material.dart';
import '../models/post.dart';

/// Full-screen viewer that lets the user swipe through a list of posts.
class PostViewerPage extends StatefulWidget {
  final List<Post> posts;
  final int initialIndex;

  const PostViewerPage({super.key, required this.posts, this.initialIndex = 0});

  @override
  State<PostViewerPage> createState() => _PostViewerPageState();
}

class _PostViewerPageState extends State<PostViewerPage> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Build the UI for a single post in the pager.
  Widget _buildPost(Post post) {
    return Column(
      children: [
        Expanded(
          child: post.mediaPath != null && post.mediaType == 'image'
              ? Image.file(File(post.mediaPath!), width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) {
            return Container(color: Colors.black, child: const Center(child: Icon(Icons.broken_image, color: Colors.white)));
          })
              : Container(
            color: Colors.black,
            child: const Center(child: Icon(Icons.videocam, color: Colors.white, size: 48)),
          ),
        ),
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(post.author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  Text(_formatTimeAgo(post.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              if (post.text.isNotEmpty) Text(post.text, style: const TextStyle(color: Colors.white70)),
              if (post.locationName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(post.locationName!, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Format a DateTime into a short "time ago" string.
  String _formatTimeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 2) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inDays < 1) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        title: Text('${_currentIndex + 1}/${posts.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: posts.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPost(post);
        },
      ),
    );
  }
}