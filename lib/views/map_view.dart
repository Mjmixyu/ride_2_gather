/**
 * map_view.dart
 *
 * File-level Dartdoc:
 * Map view that displays map tiles, user pins, and author overlays. Reads
 * pins and posts from PostRepository and computes overlays for authors'
 * latest geo-tagged posts. Allows adding pins and tapping markers to view
 * details. Uses flutter_map with OpenStreetMap tiles.
 */
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth_api.dart';
import '../services/post_repository.dart';
import '../models/post.dart';

/// MapView widget that shows a map with pins and author markers.
///
/// It loads cached posts/pins from the repository, computes overlay widget
/// positions and handles taps/long-presses for viewing or creating pins.
class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(48.2082, 16.3738);
  double _zoom = 11.0;

  List<Post> _posts = [];
  List<MapPin> _pins = [];

  final Map<String, String?> _pfpCache = {};
  final Map<String, Offset> _overlayOffsets = {};
  final Distance _distance = const Distance();

  StreamSubscription<MapEvent>? _mapEventSub;

  @override
  void initState() {
    super.initState();
    _loadInitialBounds();
    _refreshFromRepo();
    PostRepository.instance.addListener(_onRepoUpdated);
    _mapEventSub = _mapController.mapEventStream?.listen((_) {
      _updateOverlays();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlays());
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    PostRepository.instance.removeListener(_onRepoUpdated);
    super.dispose();
  }

  /// Load a preferred initial map center from stored country code if available.
  Future<void> _loadInitialBounds() async {
    try {
      final code = await PostRepository.instance.getStoredCountryCode();
      final center = _centerFromCountryCode(code);
      if (mounted) {
        setState(() {
          _center = center;
          _zoom = 11.0;
        });
      } else {
        _center = center;
        _zoom = 11.0;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(_center, _zoom);
      });
    } catch (_) {}
  }

  /// Convert a two-letter country code into a reasonable LatLng center.
  LatLng _centerFromCountryCode(String? code) {
    if (code == null || code.isEmpty) return const LatLng(48.2082, 16.3738);
    switch (code.toUpperCase()) {
      case 'AT':
        return const LatLng(48.2082, 16.3738);
      case 'DE':
        return const LatLng(52.52, 13.4050);
      case 'CH':
        return const LatLng(46.8182, 8.2275);
      case 'IT':
        return const LatLng(41.8719, 12.5674);
      case 'FR':
        return const LatLng(46.2276, 2.2137);
      case 'ES':
        return const LatLng(40.4168, -3.7038);
      case 'GB':
      case 'UK':
        return const LatLng(51.509364, -0.128928);
      case 'NL':
        return const LatLng(52.1326, 5.2913);
      case 'BE':
        return const LatLng(50.8503, 4.3517);
      case 'CZ':
        return const LatLng(50.0755, 14.4378);
      case 'PL':
        return const LatLng(52.2297, 21.0122);
      case 'US':
        return const LatLng(39.8283, -98.5795);
      default:
        return const LatLng(48.2082, 16.3738);
    }
  }

  /// Refresh local posts and pins from the PostRepository and prefetch pfps.
  void _refreshFromRepo() {
    final all = PostRepository.instance.posts;
    final pins = PostRepository.instance.pins;
    setState(() {
      _posts = all;
      _pins = pins;
    });

    for (final p in _posts) {
      if (p.author.isNotEmpty && !_pfpCache.containsKey(p.author)) _fetchAndCachePfp(p.author);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlays());
  }

  void _onRepoUpdated() {
    if (mounted) _refreshFromRepo();
  }

  /// Fetch a user's profile picture and cache the result to avoid repeated calls.
  Future<void> _fetchAndCachePfp(String username) async {
    if (username.isEmpty) return;
    if (_pfpCache.containsKey(username)) return;
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlays());
  }

  /// Build a map of the most recent post per author that includes location.
  Map<String, Post> _latestByAuthorWithLocation() {
    final Map<String, Post> latestByAuthor = {};
    for (final p in _posts) {
      if (p.lat == null || p.lon == null) continue;
      final prev = latestByAuthor[p.author];
      if (prev == null || p.createdAt.isAfter(prev.createdAt)) latestByAuthor[p.author] = p;
    }
    return latestByAuthor;
  }

  /// Compute screen-space offsets for overlays based on map projection.
  void _updateOverlays() {
    try {
      final latest = _latestByAuthorWithLocation();
      final Map<String, Offset> newOffsets = {};
      for (final entry in latest.entries) {
        final author = entry.key;
        final post = entry.value;
        if (post.lat == null || post.lon == null) continue;
        try {
          final screenPoint = _mapController.latLngToScreenPoint(LatLng(post.lat!, post.lon!));
          newOffsets[author] = Offset(screenPoint.x.toDouble(), screenPoint.y.toDouble());
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _overlayOffsets
            ..clear()
            ..addAll(newOffsets);
        });
      }
    } catch (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateOverlays());
    }
  }

  /// Handle taps on the map: open pin sheet or post sheet when near a marker.
  void _handleTap(LatLng tapped) {
    const thresholdMeters = 60;

    MapPin? nearestPin;
    double nearestPinDist = double.infinity;
    for (final pin in _pins) {
      final d = _distance.as(LengthUnit.Meter, LatLng(pin.lat, pin.lon), tapped);
      if (d < nearestPinDist) {
        nearestPinDist = d;
        nearestPin = pin;
      }
    }
    if (nearestPin != null && nearestPinDist <= thresholdMeters) {
      _openPinSheet(nearestPin);
      return;
    }

    MapEntry<String, Post>? nearestPostEntry;
    double nearestPostDist = double.infinity;
    final latest = _latestByAuthorWithLocation();
    for (final entry in latest.entries) {
      final p = entry.value;
      final d = _distance.as(LengthUnit.Meter, LatLng(p.lat!, p.lon!), tapped);
      if (d < nearestPostDist) {
        nearestPostDist = d;
        nearestPostEntry = entry;
      }
    }
    if (nearestPostEntry != null && nearestPostDist <= thresholdMeters) {
      _openPostMarkerSheet(nearestPostEntry.value);
      return;
    }
  }

  /// Show a bottom sheet with details for a post marker.
  void _openPostMarkerSheet(Post post) {
    final authorPfp = _pfpCache[post.author];
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  if (authorPfp != null && authorPfp.isNotEmpty)
                    CircleAvatar(backgroundImage: NetworkImage(authorPfp))
                  else
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text(_formatTimeAgo(post.createdAt), style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              if (post.text.isNotEmpty) Text(post.text),
              if (post.locationName != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(post.locationName!, style: const TextStyle(color: Colors.grey)),
                ])
              ],
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            ]),
          ),
        );
      },
    );
  }

  /// Show a bottom sheet with details for a map pin.
  void _openPinSheet(MapPin pin) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(pin.name ?? 'Pin', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Text(_formatTimeAgo(pin.createdAt), style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              if (pin.text != null && pin.text!.isNotEmpty) Text(pin.text!),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            ]),
          ),
        );
      },
    );
  }

  /// Format a DateTime to a short "time ago" string for display.
  String _formatTimeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 2) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inDays < 1) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  /// Prompt the user to add a pin at the given position using a dialog.
  Future<void> _onLongPressAddPin(LatLng pos) async {
    final nameCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final bool? res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Pin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (optional)')),
              TextField(controller: textCtrl, decoration: const InputDecoration(labelText: 'Description (optional)')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
          ],
        );
      },
    );

    if (res == true) {
      await PostRepository.instance.addPin(
        lat: pos.latitude,
        lon: pos.longitude,
        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        text: textCtrl.text.trim().isEmpty ? null : textCtrl.text.trim(),
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pin added')));
    }
  }

  /// Add a pin at the current center of the map.
  Future<void> _addPinAtCenter() async {
    LatLng centerPos = _center;
    try {
      final ctr = _mapController.center;
      if (ctr != null) centerPos = ctr;
    } catch (_) {}
    await _onLongPressAddPin(centerPos);
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latestByAuthorWithLocation();
    final pinCircles = _pins.map((pin) {
      return CircleMarker(
        point: LatLng(pin.lat, pin.lon),
        radius: 10.0,
        color: Colors.redAccent.withOpacity(0.95),
        borderStrokeWidth: 2,
        borderColor: Colors.white,
      );
    }).toList();
    final userCircles = latest.entries.map((e) {
      return CircleMarker(
        point: LatLng(e.value.lat!, e.value.lon!),
        radius: 8.0,
        color: Colors.blueAccent.withOpacity(0.9),
        borderStrokeWidth: 2,
        borderColor: Colors.white,
      );
    }).toList();

    final overlayWidgets = <Widget>[];
    const double overlaySize = 40.0;
    _overlayOffsets.forEach((author, offset) {
      final pfp = _pfpCache[author];
      overlayWidgets.add(Positioned(
        left: offset.dx - overlaySize / 2,
        top: offset.dy - overlaySize / 2,
        width: overlaySize,
        height: overlaySize,
        child: GestureDetector(
          onTap: () {
            final post = latest[author];
            if (post != null) _openPostMarkerSheet(post);
          },
          child: pfp != null && pfp.isNotEmpty
              ? ClipOval(child: Image.network(pfp, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person_outline)))
              : const CircleAvatar(child: Icon(Icons.person_outline)),
        ),
      ));
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add pin'),
        onPressed: _addPinAtCenter,
        tooltip: 'Add pin at map center',
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              onTap: (tapPos, latlng) {
                _handleTap(latlng);
              },
              onLongPress: (tapPos, latlng) {
                _onLongPressAddPin(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.ride2gather.app',
              ),
              CircleLayer(circles: pinCircles),
              CircleLayer(circles: userCircles),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () => launchUrl(
                      Uri.parse('https://www.openstreetmap.org/copyright'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: false,
              child: Stack(children: overlayWidgets),
            ),
          ),
        ],
      ),
    );
  }
}

extension on MapController {
  get center => null;

  latLngToScreenPoint(LatLng latLng) {}
}