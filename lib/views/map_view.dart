import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/auth_api.dart';
import '../services/post_repository.dart';
import '../models/post.dart';

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
  final Distance _distance = const Distance();

  StreamSubscription<MapEvent>? _mapEventSub;

  // UI state
  bool _ghostMode = false;
  bool _routeMarking = false;
  final List<LatLng> _routePoints = [];

  // Mock current user (replace with real location/pfp in prod)
  String _currentUsername = 'you';
  String? _currentUserPfp;
  LatLng _currentUserLocation = const LatLng(48.2082, 16.3738);

  @override
  void initState() {
    super.initState();
    _loadInitialBounds();
    _refreshFromRepo();
    PostRepository.instance.addListener(_onRepoUpdated);

    _mapEventSub = _mapController.mapEventStream.listen((evt) {
      // keep center/zoom in sync with camera
      _center = evt.camera.center;
      _zoom = evt.camera.zoom;
    });

    _fetchAndCachePfp(_currentUsername);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _posts.isEmpty) _injectMockUsers();
    });
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    PostRepository.instance.removeListener(_onRepoUpdated);
    super.dispose();
  }

  Future<void> _loadInitialBounds() async {
    try {
      final code = await PostRepository.instance.getStoredCountryCode();
      final center = _centerFromCountryCode(code);
      if (mounted) {
        setState(() {
          _center = center;
          _zoom = 11.0;
          _currentUserLocation = center;
        });
      } else {
        _center = center;
        _zoom = 11.0;
        _currentUserLocation = center;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (mounted) _mapController.move(_center, _zoom);
        } catch (_) {}
      });
    } catch (_) {}
  }

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

  void _refreshFromRepo() {
    final all = PostRepository.instance.posts;
    final pins = PostRepository.instance.pins;
    setState(() {
      _posts = all;
      _pins = pins;
    });
    for (final p in _posts) {
      if (p.author.isNotEmpty && !_pfpCache.containsKey(p.author)) {
        _fetchAndCachePfp(p.author);
      }
    }
  }

  void _onRepoUpdated() {
    if (mounted) _refreshFromRepo();
  }

  Future<void> _fetchAndCachePfp(String username) async {
    if (username.isEmpty) return;
    if (_pfpCache.containsKey(username)) return;
    _pfpCache[username] = null;
    try {
      final res = await AuthApi.getUserByUsername(username);
      if (res['ok'] == true && res['data'] != null) {
        final pfp = (res['data']['pfp'] ?? '') as String;
        _pfpCache[username] = pfp.isNotEmpty ? pfp : '';
        if (username == _currentUsername) _currentUserPfp = _pfpCache[username];
      } else {
        _pfpCache[username] = '';
        if (username == _currentUsername) _currentUserPfp = '';
      }
    } catch (_) {
      _pfpCache[username] = '';
      if (username == _currentUsername) _currentUserPfp = '';
    }
    if (mounted) setState(() {});
  }

  Map<String, Post> _latestByAuthorWithLocation() {
    final Map<String, Post> latestByAuthor = {};
    for (final p in _posts) {
      if (p.lat == null || p.lon == null) continue;
      final prev = latestByAuthor[p.author];
      if (prev == null || p.createdAt.isAfter(prev.createdAt)) {
        latestByAuthor[p.author] = p;
      }
    }
    return latestByAuthor;
  }

  void _handleTap(LatLng tapped) {
    if (_routeMarking) {
      setState(() => _routePoints.add(tapped));
      return;
    }

    const thresholdMeters = 60;

    MapPin? nearestPin;
    double nearestPinDist = double.infinity;
    for (final pin in _pins) {
      final d = _distance.as(
        LengthUnit.Meter,
        LatLng(pin.lat, pin.lon),
        tapped,
      );
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
      final d = _distance.as(
        LengthUnit.Meter,
        LatLng(p.lat!, p.lon!),
        tapped,
      );
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

  void _openPostMarkerSheet(Post post) {
    final authorPfp = _pfpCache[post.author];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (authorPfp != null && authorPfp.isNotEmpty)
                    CircleAvatar(backgroundImage: NetworkImage(authorPfp))
                  else
                    const CircleAvatar(child: Icon(Icons.person_outline)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      post.author,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _formatTimeAgo(post.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
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
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPinSheet(MapPin pin) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_pin, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pin.name ?? 'Pin',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    _formatTimeAgo(pin.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (pin.text != null && pin.text!.isNotEmpty) Text(pin.text!),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 2) return "now";
    if (diff.inHours < 1) return "${diff.inMinutes}m";
    if (diff.inDays < 1) return "${diff.inHours}h";
    return "${diff.inDays}d";
  }

  Future<void> _onLongPressAddPin(LatLng pos) async {
    final nameCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    final bool? res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
      ),
    );

    if (res == true) {
      await PostRepository.instance.addPin(
        lat: pos.latitude,
        lon: pos.longitude,
        name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
        text: textCtrl.text.trim().isEmpty ? null : textCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pin added')));
      }
    }
  }

  Future<void> _addPinAtCenter() => _onLongPressAddPin(_center);

  void _clearRoute() {
    setState(() {
      _routePoints.clear();
      _routeMarking = false;
    });
  }

  void _injectMockUsers() {
    final now = DateTime.now();
    final nearby = [
      Post(
        id: 'mock1',
        author: 'alice',
        text: 'Hey from nearby!',
        createdAt: now.subtract(const Duration(minutes: 3)),
        lat: _currentUserLocation.latitude + 0.007,
        lon: _currentUserLocation.longitude + 0.006,
        locationName: 'Near you', mediaType: '',
      ),
      Post(
        id: 'mock2',
        author: 'bob',
        text: 'On a ride',
        createdAt: now.subtract(const Duration(minutes: 20)),
        lat: _currentUserLocation.latitude - 0.006,
        lon: _currentUserLocation.longitude - 0.005,
        locationName: 'Park', mediaType: '',
      ),
      Post(
        id: 'mock3',
        author: 'carla',
        text: 'Coffee stop',
        createdAt: now.subtract(const Duration(hours: 1)),
        lat: _currentUserLocation.latitude + 0.01,
        lon: _currentUserLocation.longitude - 0.008,
        locationName: 'Cafe', mediaType: '',
      ),
    ];
    setState(() => _posts.addAll(nearby));
    for (final p in nearby) {
      _fetchAndCachePfp(p.author);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latestByAuthorWithLocation();

    // pin circles
    final pinCircles = _pins
        .map(
          (pin) => CircleMarker(
        point: LatLng(pin.lat, pin.lon),
        radius: 10.0,
        color: Colors.redAccent.withOpacity(0.95),
        borderStrokeWidth: 2,
        borderColor: Colors.white,
      ),
    )
        .toList();

    final double otherUsersOpacity = _ghostMode ? 0.35 : 0.9;

    // other users as markers (Marker.child API)
    final List<Marker> otherUserMarkers = latest.entries.map((e) {
      final p = e.value;
      final pfp = _pfpCache[p.author];
      return Marker(
        point: LatLng(p.lat!, p.lon!),
        width: 40,
        height: 40,
        child: Opacity(
          opacity: otherUsersOpacity,
          child: GestureDetector(
            onTap: () => _openPostMarkerSheet(p),
            child: pfp != null && pfp.isNotEmpty
                ? ClipOval(
              child: Image.network(
                pfp,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                const CircleAvatar(child: Icon(Icons.person_outline)),
              ),
            )
                : const CircleAvatar(child: Icon(Icons.person_outline)),
          ),
        ),
      );
    }).toList();

    // current user marker
    final currentUserMarker = Marker(
      point: _currentUserLocation,
      width: 48,
      height: 48,
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (ctx) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    if (_currentUserPfp != null && _currentUserPfp!.isNotEmpty)
                      CircleAvatar(backgroundImage: NetworkImage(_currentUserPfp!))
                    else
                      const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This is you (mocked)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        child: _currentUserPfp != null && _currentUserPfp!.isNotEmpty
            ? ClipOval(
          child: Image.network(
            _currentUserPfp!,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey,
              ),
              child: const Icon(Icons.person),
            ),
          ),
        )
            : Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green,
          ),
          child: const Icon(Icons.person, color: Colors.white),
        ),
      ),
    );

    final List<Marker> allMarkers = [...otherUserMarkers, currentUserMarker];

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
              onTap: (tapPos, latlng) => _handleTap(latlng),
              onLongPress: (tapPos, latlng) {
                if (!_routeMarking) _onLongPressAddPin(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.ride2gather.app',
              ),
              CircleLayer(circles: pinCircles),
              if (allMarkers.isNotEmpty) MarkerLayer(markers: allMarkers),
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.purpleAccent, // like in the screenshot
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    '© OpenStreetMap contributors',
                    onTap: () async {
                      final uri = Uri.parse('https://www.openstreetmap.org/copyright');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),

          // ===== RIGHT-SIDE TOOLS =====
          Positioned(
            right: 12,
            top: 90,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'ghost_mode',
                  mini: true,
                  backgroundColor: _ghostMode ? Colors.white : Colors.black87,
                  onPressed: () {
                    setState(() => _ghostMode = !_ghostMode);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ghost mode ${_ghostMode ? 'on' : 'off'}')),
                    );
                  },
                  child: Icon(Icons.hide_source , color: _ghostMode ? Colors.black : Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'route_mark',
                  mini: true,
                  backgroundColor: _routeMarking ? Colors.purpleAccent : Colors.black87,
                  onPressed: () {
                    setState(() => _routeMarking = !_routeMarking);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_routeMarking
                            ? 'Route marking: tap to add points'
                            : 'Route marking off'),
                      ),
                    );
                  },
                  child: const Icon(Icons.add_road, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'route_clear',
                  mini: true,
                  backgroundColor: Colors.black87,
                  onPressed: _routePoints.isNotEmpty ? _clearRoute : null,
                  child: const Icon(Icons.clear, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'route_done',
                  mini: true,
                  backgroundColor: _routePoints.length >= 2 ? Colors.green : Colors.grey,
                  onPressed: _routePoints.length >= 2
                      ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Route with ${_routePoints.length} points saved (mock)')),
                    );
                    setState(() => _routeMarking = false);
                  }
                      : null,
                  child: const Icon(Icons.check, color: Colors.white),
                ),
              ],
            ),
          ),

          // ===== BOTTOM ACTION CHIPS (Challenges, Add a photo, etc.) =====
          Positioned(
            left: 12,
            right: 12,
            bottom: 18,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: const [
                  _ActionChipCard(icon: Icons.emoji_events_outlined, label: 'Challenges'),
                  SizedBox(width: 10),
                  _ActionChipCard(icon: Icons.add_a_photo_outlined, label: 'Add a photo'),
                  SizedBox(width: 10),
                  _ActionChipCard(icon: Icons.warning_amber_rounded, label: 'CRASH-LIGHT'),
                  SizedBox(width: 10),
                  _ActionChipCard(icon: Icons.settings, label: 'Settings'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Small UI helpers =====

class _TripStat extends StatelessWidget {
  final String label;
  final String value;
  const _TripStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, letterSpacing: 0.8)),
      ],
    );
  }
}

class _TripDivider extends StatelessWidget {
  const _TripDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white24,
    );
  }
}

class _ActionChipCard extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ActionChipCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
