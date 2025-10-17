# Map Widget

## Overview

The `MapWidget` is a reusable Flutter widget that provides an interactive map with user location tracking.

## Features

- **Default Center**: Salzburg, Austria (47.8095°N, 13.0550°E)
- **User Location**: Shows the user's current position as a blue dot with a white border
- **Light Theme**: Clean, light map style using OpenStreetMap standard tiles
- **Interactive**: Users can zoom (from world view to street level) and pan across the entire map
- **Location Button**: Floating button to quickly center the map on user's current location
- **Permission Handling**: Automatically requests and handles location permissions
- **Error Messages**: Clear feedback when location services are unavailable

## Usage

### Basic Usage

```dart
import 'package:ride2gather/widgets/map_widget.dart';

// In your widget tree
MapWidget()
```

### In a Scaffold

```dart
import 'package:flutter/material.dart';
import 'package:ride2gather/widgets/map_widget.dart';

class MyMapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      body: MapWidget(),
    );
  }
}
```

## Requirements

### Dependencies

Ensure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_map: ^7.0.0
  latlong2: ^0.9.0
  geolocator: ^12.0.0
```

### Platform Configuration

#### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET"/>
```

#### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to show your position on the map.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to your location to show your position on the map.</string>
```

## Map Controls

- **Pinch/Spread**: Zoom in/out
- **Drag**: Pan the map
- **Blue Button**: Center map on user location (appears after location is loaded)

## States

1. **Loading**: Shows a loading indicator while fetching user location
2. **Location Available**: Displays blue dot at user's position with center button
3. **Location Error**: Shows error message banner (can be dismissed)
4. **No Location**: Map works normally without user location marker

## Map Configuration

- **Zoom Range**: 2.0 (world view) to 18.0 (street level)
- **Default Zoom**: 13.0 (city view)
- **Tile Provider**: OpenStreetMap standard tiles (light, clean style)
- **User Agent**: com.ride2gather.app

## Notes

- The widget automatically handles location permission requests
- Location tracking is only active when the widget is initialized
- The map can be used without location permissions (just won't show user position)
- Internet connection required for map tiles
