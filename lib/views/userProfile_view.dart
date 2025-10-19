import 'package:flutter/material.dart';
import 'user_settings_view.dart';
import '../theme/auth_theme.dart';

class UserProfilePage extends StatelessWidget {
  final String username;
  final String bio;
  final String bike;
  final String pfpUrl;
  final String? viewerUsername; // who's viewing the profile (nullable)

  const UserProfilePage({
    Key? key,
    required this.username,
    required this.bio,
    required this.bike,
    required this.pfpUrl,
    this.viewerUsername,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example posts list
    final List<String> posts = List.generate(12, (i) => "post_$i");
    final mediaTopHeight = 300.0;

    // Determine if the current viewer is the profile owner
    final bool isOwnProfile = viewerUsername != null && viewerUsername == username;

    return Scaffold(
      // keep scaffold's background as gradient to match auth screens
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AuthTheme.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Top profile banner implemented as a Stack so the settings button can be anchored
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: mediaTopHeight,
                child: ClipRect(
                  child: Stack(
                    children: [
                      // Background image or solid color
                      Positioned.fill(
                        child: pfpUrl.isNotEmpty
                            ? Image.network(
                          pfpUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: mediaTopHeight,
                          alignment: Alignment.topCenter,
                        )
                            : Container(
                          color: const Color(0xFF000080),
                          child: const Center(
                            child: Icon(Icons.person, size: 96, color: Colors.white70),
                          ),
                        ),
                      ),

                      // Subtle gradient overlay for readability (covers image smoothly)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.06),
                                Colors.black.withOpacity(0.28),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Main content positioned below the top banner (the top of this container slightly overlaps the image to create a smooth transition)
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  children: [
                    // Reserve space so the top image remains visible to the very top.
                    // Reduced the spacer by 12 pixels so the content will overlap the image
                    SizedBox(height: mediaTopHeight - 102),

                    // Dark rounded content area that matches auth design
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(24),
                            topRight: Radius.circular(24),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),

                            // Username + follow button (follow only when viewing others)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Username column
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "@$username",
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          bio,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Right side: Follow button only if viewing other profiles
                                  if (!isOwnProfile)
                                    SizedBox(
                                      height: 38,
                                      child: ElevatedButton(
                                        style: AuthTheme.mainButtonStyle.copyWith(
                                          padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          ),
                                        ),
                                        onPressed: () {},
                                        child: const Text("Follow", style: TextStyle(fontSize: 14)),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Bike placeholder
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Center(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0),
                                  height: 140,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.motorcycle, size: 80, color: Colors.black),
                                        if (bike.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              bike,
                                              style: const TextStyle(fontSize: 14, color: Colors.black),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Posts grid
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: GridView.builder(
                                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 6,
                                    mainAxisSpacing: 6,
                                  ),
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.image, color: Colors.white),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Settings button: placed last in the Stack so it's on top and receives taps.
            Positioned(
              // place slightly below the bottom edge of the top image (overlapping the content)
              top: mediaTopHeight - 36,
              right: 16,
              child: Material(
                // Material used to get proper elevation/shadow and to ensure taps are recognized
                color: Colors.transparent,
                elevation: 6,
                shape: const CircleBorder(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.06), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: "User Settings",
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => UserSettingsPage(
                            username: username,
                            bio: bio,
                            bike: bike,
                            pfpUrl: pfpUrl,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}