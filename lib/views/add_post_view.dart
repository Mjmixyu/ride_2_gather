import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddPostView extends StatefulWidget {
  const AddPostView({super.key});

  @override
  State<AddPostView> createState() => _AddPostViewState();
}

class _AddPostViewState extends State<AddPostView> {
  File? _mediaFile;
  String _mediaType = ""; // "image", "video", or ""
  final _textController = TextEditingController();
  final _bioController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    XFile? pickedFile;
    if (isVideo) {
      pickedFile = await _picker.pickVideo(source: source);
    } else {
      pickedFile = await _picker.pickImage(source: source);
    }
    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile!.path);
        _mediaType = isVideo ? "video" : "image";
      });
    }
  }

  void _submitPost() {
    String content;
    if (_mediaType == "") {
      content = _textController.text;
    } else {
      content = "Media: $_mediaType | Bio: ${_bioController.text}";
    }
    // TODO: Implement actual post upload logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post created: $content')),
    );
    setState(() {
      _mediaFile = null;
      _mediaType = "";
      _textController.clear();
      _bioController.clear();
    });
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
                  onPressed: () => _pickMedia(ImageSource.gallery, isVideo: false),
                  icon: const Icon(Icons.image),
                  label: const Text('Add Image'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickMedia(ImageSource.gallery, isVideo: true),
                  icon: const Icon(Icons.videocam),
                  label: const Text('Add Video'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: TextField(
                    controller: _textController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Write something...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _mediaType == "image"
                    ? Image.file(_mediaFile!, height: 200, fit: BoxFit.cover)
                    : const Icon(Icons.videocam, size: 200), // Placeholder for video preview
                const SizedBox(height: 10),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Add a bio/caption...',
                    border: OutlineInputBorder(),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _mediaFile = null;
                      _mediaType = "";
                      _bioController.clear();
                    });
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Media'),
                ),
              ],
            ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: (_mediaFile == null && _textController.text.isEmpty)
                ? null
                : _submitPost,
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}