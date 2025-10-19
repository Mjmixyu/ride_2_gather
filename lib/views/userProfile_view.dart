import 'package:flutter/material.dart';
import 'user_settings_view.dart';

class UserProfilePage extends StatelessWidget {
  final String username;
  final String bio;
  final String bike;
  final String pfpUrl;

  const UserProfilePage({
    Key? key,
    required this.username,
    required this.bio,
    required this.bike,
    required this.pfpUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Example posts list
    final List<String> posts = List.generate(12, (i) => "post_$i");

    return Column(
      children: [
        // Profile picture with settings button overlay (bottom right)
        Stack(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: pfpUrl.isNotEmpty
                  ? Image.network(
                      pfpUrl,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.person, size: 100, color: Colors.white),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 28,
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
          ],
        ),
        // Blue section
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF000080),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username + follow button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "@$username",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {},
                        child: const Text("Follow"),
                      ),
                    ],
                  ),
                ),
                // Bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    bio,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                // Bike placeholder
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.motorcycle,
                      size: 120,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Posts grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}
