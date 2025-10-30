/**
 * posts_api.dart
 *
 * File-level Dartdoc:
 * Provides helper functions for uploading posts that may include optional
 * media files. The PostsApi class contains a single uploadPost static method
 * that constructs a multipart request and returns a structured response map.
 */
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

/// A collection of static methods for interacting with post-related server endpoints.
class PostsApi {
  static const String _base = 'http://10.0.2.2:3000';

  /// Uploads a post to the server including optional media (image or video).
  ///
  /// @param author The username of the post author.
  /// @param text The textual content of the post.
  /// @param mediaFile Optional file to upload as media for the post.
  /// @param mediaType One of 'image', 'video', or an empty string when no media is present.
  /// @param token Optional bearer token for authorization.
  /// @return A map with 'ok' true and 'data' on success, or 'ok' false and 'error' message on failure.
  static Future<Map<String, dynamic>> uploadPost({
    required String author,
    required String text,
    File? mediaFile,
    required String mediaType, // 'image' | 'video' | ''
    String? token,
  }) async {
    final uri = Uri.parse('$_base/post');
    final request = http.MultipartRequest('POST', uri);

    request.fields['author'] = author;
    request.fields['text'] = text;
    request.fields['mediaType'] = mediaType;

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (mediaFile != null) {
      final mimeType = lookupMimeType(mediaFile.path) ?? 'application/octet-stream';
      final parts = mimeType.split('/');
      final contentType = MediaType(parts[0], parts.length > 1 ? parts[1] : 'octet-stream');

      final multipartFile = await http.MultipartFile.fromPath(
        'media',
        mediaFile.path,
        contentType: contentType,
      );
      request.files.add(multipartFile);
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body.isEmpty ? '{}' : res.body);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return {'ok': true, 'data': body};
    }

    final msg = body['error']?.toString() ?? 'Upload failed';
    return {'ok': false, 'error': msg};
  }
}