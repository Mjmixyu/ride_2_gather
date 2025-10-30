/**
 * post_repository.dart
 *
 * File-level Dartdoc:
 * Singleton repository that manages local posts and map pins, persists them to
 * the application's documents directory, and coordinates uploads to the remote
 * PostsApi when available. It also exposes a ValueNotifier for UI actions
 * (for example requesting a tab switch) and helpers to read/write a stored
 * country code via SharedPreferences.
 */
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';
import '../core/posts_api.dart';

/// Simple model representing a pin placed on the map.
///
/// Contains coordinates, optional name and text, and a creation timestamp.
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

  /// Convert this MapPin into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lon': lon,
    'name': name,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Create a MapPin instance from a JSON map.
  static MapPin fromJson(Map<String, dynamic> j) => MapPin(
    id: j['id'] as String,
    lat: (j['lat'] as num).toDouble(),
    lon: (j['lon'] as num).toDouble(),
    name: j['name'] as String?,
    text: j['text'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

/// Repository that stores posts and pins locally, persists them, and notifies listeners.
///
/// Use PostRepository.instance to access the singleton.
class PostRepository extends ChangeNotifier {
  static final PostRepository instance = PostRepository._internal();
  factory PostRepository() => instance;
  PostRepository._internal();

  final Uuid _uuid = const Uuid();

  late Directory _appDir;
  final List<Post> _posts = [];
  final List<MapPin> _pins = [];
  bool _initialized = false;

  /// Notifier other widgets can use to request UI actions (for example switching tabs).
  final ValueNotifier<int?> tabRequest = ValueNotifier<int?>(null);

  List<Post> get posts => List.unmodifiable(_posts);
  List<MapPin> get pins => List.unmodifiable(_pins);

  /// Initialize repository: set application directory, load saved posts and pins,
  /// and ensure SharedPreferences is available. Safe to call multiple times.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    _appDir = await getApplicationDocumentsDirectory();

    final postsFile = File(p.join(_appDir.path, 'posts.json'));
    if (await postsFile.exists()) {
      try {
        final raw = await postsFile.readAsString();
        final arr = json.decode(raw) as List<dynamic>;
        for (final item in arr) {
          _posts.add(Post.fromJson(item as Map<String, dynamic>));
        }
      } catch (e) {
        if (kDebugMode) print('Failed reading posts.json: $e');
      }
    }

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

    await SharedPreferences.getInstance();

    notifyListeners();
  }

  /// Persist the in-memory posts list to posts.json.
  Future<void> _savePosts() async {
    final postsFile = File(p.join(_appDir.path, 'posts.json'));
    final arr = _posts.map((p) => p.toJson()).toList();
    await postsFile.writeAsString(json.encode(arr));
  }

  /// Persist the in-memory pins list to pins.json.
  Future<void> _savePins() async {
    final pinsFile = File(p.join(_appDir.path, 'pins.json'));
    final arr = _pins.map((p) => p.toJson()).toList();
    await pinsFile.writeAsString(json.encode(arr));
  }

  /// Add a post locally and attempt to upload it to the server asynchronously.
  ///
  /// The mediaFile (if provided) is copied into the app directory to maintain
  /// a stable local reference. The function inserts the new post at the front
  /// of the local list, saves posts.json, notifies listeners, and triggers an
  /// asynchronous upload via PostsApi. If the server returns an id or createdAt
  /// timestamp, the local post is updated accordingly.
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

  /// Create and persist a new MapPin.
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

  /// Clear all stored posts and pins from memory and disk.
  Future<void> clearAll() async {
    _posts.clear();
    _pins.clear();
    await _savePosts();
    await _savePins();
    notifyListeners();
  }

  /// Retrieve the stored country code from SharedPreferences, if any.
  Future<String?> getStoredCountryCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('country_code');
  }

  /// Store the country code string in SharedPreferences.
  Future<void> setStoredCountryCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('country_code', code);
  }
}