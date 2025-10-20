// lib/views/user_settings_page.dart
// Updated to use Bike enum list from models/bike.dart instead of the hardcoded bikeTypes list.

import 'package:flutter/material.dart';
import '../theme/auth_theme.dart';
import '../models/bike.dart';
import '../core/auth_api.dart';

class UserSettingsPage extends StatefulWidget {
  final int userId;
  final String username;
  final String bio;
  final String bike;
  final String pfpUrl;

  const UserSettingsPage({
    Key? key,
    required this.userId,
    required this.username,
    required this.bio,
    required this.bike,
    required this.pfpUrl,
  }) : super(key: key);

  @override
  State<UserSettingsPage> createState() => _UserSettingsPageState();
}

class _UserSettingsPageState extends State<UserSettingsPage> {
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  String? _bikeType;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
    _bikeType = widget.bike.isNotEmpty ? widget.bike : null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      // call API to update bio and bike (bike name is saved as provided)
      final result = await AuthApi.updateUserSettings(
        userId: widget.userId,
        bio: _bioController.text.trim(),
        bikeName: _bikeType,
      );

      if (result['ok'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
          // Return true so caller can refresh
          Navigator.of(context).pop(true);
        }
      } else {
        final err = (result['error'] ?? 'Save failed').toString();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Network error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onChangePfp() {
    // Placeholder: UI only. In real app you would open image picker and upload.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Change PFP tapped (image picker not implemented here)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topBannerHeight = 140.0;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                // Top banner with pfp (if provided) to keep visual consistency with profile
                SizedBox(
                  height: topBannerHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: widget.pfpUrl.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.pfpUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      // Small overlay showing that the user can change their PFP
                      Positioned(
                        left: 12,
                        bottom: 12,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white,
                              backgroundImage:
                              widget.pfpUrl.isNotEmpty ? NetworkImage(widget.pfpUrl) as ImageProvider : null,
                              child: widget.pfpUrl.isEmpty ? const Icon(Icons.person, size: 32, color: Colors.black54) : null,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Profile Picture',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                TextButton.icon(
                                  onPressed: _onChangePfp,
                                  icon: const Icon(Icons.upload_file, color: Colors.white),
                                  label: const Text('Change PFP', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Main settings card (dark rounded)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: AuthTheme.textFieldDecoration(
                            hintText: 'Username',
                            icon: Icons.person_outline,
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Please enter username' : null,
                        ),
                        const SizedBox(height: 12),

                        // Bio with a different icon (not info)
                        TextFormField(
                          controller: _bioController,
                          style: const TextStyle(color: Colors.white),
                          decoration: AuthTheme.textFieldDecoration(
                            hintText: 'Bio',
                            icon: Icons.note_alt, // changed icon
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 12),

                        // Bike type dropdown — now using Bike enum list
                        DropdownButtonFormField<String>(
                          value: _bikeType,
                          dropdownColor: const Color(0xFF1A1A3C),
                          style: const TextStyle(color: Colors.white),
                          decoration: AuthTheme.textFieldDecoration(
                            hintText: 'Select bike type',
                            icon: Icons.motorcycle,
                          ),
                          items: allBikes
                              .map((b) => DropdownMenuItem<String>(
                            value: b.displayName,
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Image.asset(
                                    '${b.assetPath}.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.pedal_bike, size: 18, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(b.displayName),
                              ],
                            ),
                          ))
                              .toList(),
                          onChanged: (val) => setState(() => _bikeType = val),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: AuthTheme.mainButtonStyle,
                            onPressed: _saving ? null : _onSave,
                            child: _saving
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Text('Save', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              side: BorderSide(color: Colors.white.withOpacity(0.08)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}