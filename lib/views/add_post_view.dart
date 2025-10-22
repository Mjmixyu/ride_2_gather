import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/post_repository.dart';

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
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose Photo'),
                onTap: () => Navigator.of(ctx).pop(0),
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Choose Video'),
                onTap: () => Navigator.of(ctx).pop(1),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
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
      // Use real author passed into widget
      final author = widget.author;

      final created = await PostRepository.instance.addPost(
        author: author,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Create New Post', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (_mediaFile == null)
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _showAddMediaSheet,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Add Media'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Write something...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                if (_mediaType == "image")
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_mediaFile!, width: double.infinity, height: 240, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Icon(Icons.videocam, size: 64)),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: _textController,
                  maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Write a caption...', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _mediaFile = null;
                      _mediaType = "";
                    });
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Media'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: (_mediaFile == null && _textController.text.isEmpty) || _submitting ? null : _submitPost,
            icon: _submitting ? const SizedBox.shrink() : const Icon(Icons.send),
            label: Text(_submitting ? 'Posting...' : 'Post'),
          ),
        ],
      ),
    );
  }
}