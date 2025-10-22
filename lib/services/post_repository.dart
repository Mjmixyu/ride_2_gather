import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';
import '../core/posts_api.dart';

class MapPin {
  final String id;
  final double lat;
  final double lon;
  final String? name;
  final String? text;
  final DateTime createdAt;

  MapPin({
    required this.id,
    required this.lat,
    required this.lon,
    this.name,
    this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lon': lon,
    'name': name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  static MapPin fromJson(Map<String, dynamic> j) => MapPin(
    id: j['id'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    name: j['name'] as String?,
    text: j['text'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

class PostRepository extends ChangeNotifier {
  static final PostRepository instance = PostRepository._internal();
  factory PostRepository() => instance;
  PostRepository._internal();

  final Uuid _uuid = const Uuid();

  late Directory _appDir;
  final List<Post> _posts = [];
  final List<MapPin> _pins = [];
  bool _initialized = false;

  // Notifier used to request UI actions from other widgets (e.g. switch tab).
  final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

  List<Post> get posts => List.unmodifiable(_posts);
  List<MapPin> get pins => List.unmodifiable(_pins);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _appDir = await getApplicationDocumentsDirectory();

    // load posts
    final postsFile = File(p.join(_appDir.path, 'posts.json'));
    if (await postsFile.exists()) {
      try {
        final raw = await postsFile.readAsString();
        final arr = json.decode(raw) as List<dynamic>;
        for (final item in arr) {
          _posts.add(Post.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        // ignore parse errors for now
        if (kDebugMode) print('Failed reading posts.json: $e');
      }
    }

    // load pins
    final pinsFile = File(p.join(_appDir.path, 'pins.json'));
    if (await pinsFile.exists()) {
      try {
        final raw = await pinsFile.readAsString();
        final arr = json.decode(raw) as List<dynamic>;
        for (final item in arr) {
          _pins.add(MapPin.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        if (kDebugMode) print('Failed reading pins.json: $e');
      }
    }

    // ensure SharedPreferences is available (used for country_code)
    await SharedPreferences.getInstance();

    notifyListeners();
  }

  Future<void> _savePosts() async {
    final postsFile = File(p.join(_appDir.path, 'posts.json'));
    final arr = _posts.map((p) => p.toJson()).toList();
    await postsFile.writeAsString(json.encode(arr));
  }

  Future<void> _savePins() async {
    final pinsFile = File(p.join(_appDir.path, 'pins.json'));
    final arr = _pins.map((p) => p.toJson()).toList();
    await pinsFile.writeAsString(json.encode(arr));
  }

  // add a post locally and attempt to upload to server (if PostsApi._base is reachable).
  // returns the created local Post.
  Future<Post> addPost({
    required String author,
    required String text,
    File? mediaFile,
    required String mediaType,
    double? lat,
    double? lon,
    String? locationName,
    String? authToken,
  }) async {
    String? savedPath;
    if (mediaFile != null) {
      final ext = p.extension(mediaFile.path);
      final filename = '${_uuid.v4()}$ext';
      final dest = File(p.join(_appDir.path, filename));
      await mediaFile.copy(dest.path);
      savedPath = dest.path;
    }

    final post = Post(
      id: _uuid.v4(),
      author: author,
      text: text,
      mediaType: mediaType,
      mediaPath: savedPath,
      createdAt: DateTime.now(),
      lat: lat,
      lon: lon,
      locationName: locationName,
    );

    _posts.insert(0, post);
    await _savePosts();
    notifyListeners();

    // Try upload to server asynchronously — don't block user if server is down.
    try {
      final mediaForUpload = mediaFile != null ? File(savedPath ?? mediaFile.path) : null;
      final resp = await PostsApi.uploadPost(
        author: author,
        text: text,
        mediaFile: mediaForUpload,
        mediaType: mediaType,
        token: authToken,
      );

      if (kDebugMode) {
        if (resp['ok'] == true) {
          debugPrint('Post uploaded to server successfully: ${resp['data']}');
        } else {
          debugPrint('Server upload failed: ${resp['error']}');
        }
      }

      // If server returned an id / createdAt, store them locally so profile/feed can use server info.
      if (resp['ok'] == true && resp['data'] != null) {
        final data = resp['data'] as Map<String, dynamic>;
        final serverId = data['id']?.toString();
        DateTime? serverCreated;
        if (data['createdAt'] != null) {
          try {
            serverCreated = DateTime.parse(data['createdAt'] as String);
          } catch (_) {}
        }

        if (serverId != null) {
          // find local post by matching unique fields (here we use the generated local id)
          final idx = _posts.indexWhere((p) => p.id == post.id);
          if (idx != -1) {
            final updated = _posts[idx].copyWith(serverId: serverId, serverCreatedAt: serverCreated);
            _posts[idx] = updated;
            await _savePosts();
            notifyListeners();
            if (kDebugMode) debugPrint('Local post updated with serverId=$serverId');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('PostsApi.uploadPost error: $e');
    }

    return post;
  }

  Future<void> addPin({
    required double lat,
    required double lon,
    String? name,
    String? text,
  }) async {
    final pin = MapPin(
      id: _uuid.v4(),
      lat: lat,
      lon: lon,
      name: name,
      text: text,
      createdAt: DateTime.now(),
    );
    _pins.add(pin);
    await _savePins();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _posts.clear();
    _pins.clear();
    await _savePosts();
    await _savePins();
    notifyListeners();
  }

  Future<String?> getStoredCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('country_code');
  }

  Future<void> setStoredCountryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('country_code', code);
  }
}