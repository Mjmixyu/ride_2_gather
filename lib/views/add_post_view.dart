import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/post_repository.dart';
import '../theme/auth_theme.dart';

class AddPostView extends StatefulWidget {
  final String author;
  const AddPostView({super.key, required this.author});

  @override
  State<AddPostView> createState() => _AddPostViewState();
}

class _AddPostViewState extends State<AddPostView> {
  File? _mediaFile;
  String _mediaType = ""; // "image", "video", or ""
  final _textController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;

  Future<void> _pickMediaFromGallery({required bool isVideo}) async {
    XFile? pickedFile;
    if (isVideo) {
      pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
        _mediaType = isVideo ? "video" : "image";
      });
    }
  }

  Future<void> _showAddMediaSheet() async {
    final res = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.75),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border.all(color: Colors.white.withOpacity(0.03)),
            ),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.white70),
                  title: const Text('Choose Photo', style: TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.of(ctx).pop(0),
                ),
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.white70),
                  title: const Text('Choose Video', style: TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.of(ctx).pop(1),
                ),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.white70),
                  title: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (res == 0) {
      await _pickMediaFromGallery(isVideo: false);
    } else if (res == 1) {
      await _pickMediaFromGallery(isVideo: true);
    }
  }

  Future<void> _submitPost() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final textContent = _textController.text.trim();
    final bio = _bioController.text.trim();

    try {
      await PostRepository.instance.addPost(
        author: widget.author,
        text: textContent.isEmpty ? bio : textContent,
        mediaFile: _mediaFile,
        mediaType: _mediaType,
      );

      if (!mounted) return;

      messenger.showSnackBar(const SnackBar(content: Text('Post created')));

      // request HomeFeed to switch back to feed (tab index 0)
      PostRepository.instance.tabRequest.value = 0;

      // reset UI
      setState(() {
        _mediaFile = null;
        _mediaType = "";
        _textController.clear();
        _bioController.clear();
      });
    } catch (e) {
      if (mounted) messenger.showSnackBar(SnackBar(content: Text('Failed to create post: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // full-screen gradient background like Login/Signup
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: AuthTheme.backgroundGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              // Centered card like signup
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text('Create New Post', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.06),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Media'),
                        onPressed: _showAddMediaSheet,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_mediaFile != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _mediaType == 'image'
                            ? Image.file(_mediaFile!, height: 220, width: double.infinity, fit: BoxFit.cover)
                            : Container(
                          height: 220,
                          color: Colors.grey.shade900,
                          child: const Center(child: Icon(Icons.videocam, size: 64, color: Colors.white70)),
                        ),
                      ),
                    if (_mediaFile != null) const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: _mediaFile == null ? 5 : 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _mediaFile == null ? 'Write something...' : 'Write a caption...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.03),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: AuthTheme.mainButtonStyle.copyWith(
                        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                      ),
                      onPressed: (_mediaFile == null && _textController.text.isEmpty) || _submitting ? null : _submitPost,
                      child: Text(_submitting ? 'Posting...' : 'Post'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}