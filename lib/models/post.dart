/**
 * post_model.dart
 *
 * File-level Dartdoc:
 * Defines the Post model used by the application to represent user posts.
 * Includes serialization helpers, a copyWith constructor, and conversion to/from raw JSON.
 */
import 'dart:convert';

class Post {
  final String id;
  final String? serverId;
  final String author;
  final String text;
  final String? mediaPath;
  final String mediaType;
  final DateTime createdAt;
  final DateTime? serverCreatedAt;
  final double? lat;
  final double? lon;
  final String? locationName;

  /// Post model representing a user-created post with optional media and location.
  ///
  /// @param id Local unique identifier for the post.
  /// @param author Username of the post author.
  /// @param text Text content of the post.
  /// @param mediaType The type of media ('image', 'video', or '').
  /// @param mediaPath Optional local path to media file.
  /// @param createdAt Optional creation time; defaults to now if null.
  /// @param serverId Optional server-assigned ID for the post.
  /// @param serverCreatedAt Optional server timestamp for creation.
  /// @param lat Optional latitude of the post location.
  /// @param lon Optional longitude of the post location.
  /// @param locationName Optional human-readable location name.
  Post({
    required this.id,
    required this.author,
    required this.text,
    required this.mediaType,
    this.mediaPath,
    DateTime? createdAt,
    this.serverId,
    this.serverCreatedAt,
    this.lat,
    this.lon,
    this.locationName,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of this Post with the provided fields replaced.
  ///
  /// @return A new Post instance with the updated values.
  Post copyWith({
    String? id,
    String? serverId,
    String? author,
    String? text,
    String? mediaPath,
    String? mediaType,
    DateTime? createdAt,
    DateTime? serverCreatedAt,
    double? lat,
    double? lon,
    String? locationName,
  }) {
    return Post(
      id: id ?? this.id,
      author: author ?? this.author,
      text: text ?? this.text,
      mediaPath: mediaPath ?? this.mediaPath,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      serverId: serverId ?? this.serverId,
      serverCreatedAt: serverCreatedAt ?? this.serverCreatedAt,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      locationName: locationName ?? this.locationName,
    );
  }

  /// Converts this Post instance to a JSON-compatible map.
  ///
  /// @return A Map<String, dynamic> suitable for JSON encoding.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serverId': serverId,
      'author': author,
      'text': text,
      'mediaPath': mediaPath,
      'mediaType': mediaType,
      'createdAt': createdAt.toIso8601String(),
      'serverCreatedAt': serverCreatedAt?.toIso8601String(),
      'lat': lat,
      'lon': lon,
      'locationName': locationName,
    };
  }

  /// Constructs a Post from a JSON map produced by toJson().
  ///
  /// @param j The JSON map to parse.
  /// @return A Post instance with fields parsed from the map.
  static Post fromJson(Map<String, dynamic> j) {
    return Post(
      id: j['id'] as String,
      serverId: j['serverId'] as String?,
      author: j['author'] as String,
      text: j['text'] as String,
      mediaPath: j['mediaPath'] as String?,
      mediaType: j['mediaType'] as String? ?? '',
      createdAt: DateTime.parse(j['createdAt'] as String),
      serverCreatedAt: j['serverCreatedAt'] != null ? DateTime.parse(j['serverCreatedAt'] as String) : null,
      lat: j['lat'] != null ? (j['lat'] as num).toDouble() : null,
      lon: j['lon'] != null ? (j['lon'] as num).toDouble() : null,
      locationName: j['locationName'] as String?,
    );
  }

  /// Serializes this Post to a raw JSON string.
  ///
  /// @return A JSON string representing this Post.
  String toRawJson() => json.encode(toJson());
}