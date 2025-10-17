# ride2gather

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Map Widget

The app includes a reusable map widget (`lib/widgets/map_widget.dart`) that:
- Displays a map centered on Salzburg, Austria by default
- Shows the user's current location as a blue dot (requires location permissions)
- Uses a light, clean map style with OpenStreetMap tiles
- Allows users to zoom out and pan to view the entire world map
- Includes a button to center the map on the user's current location

### Location Permissions

The map widget requires location permissions to display the user's current position:

**iOS**: Location permissions are configured in `ios/Runner/Info.plist`
**Android**: Location permissions are configured in `android/app/src/main/AndroidManifest.xml`

The widget will automatically request permissions when first loaded.
