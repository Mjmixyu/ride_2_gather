import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  final String username;
  final String bio;

  UserProfilePage({super.key, required this.username, this.bio = "stuff abt me"});

  // Example posts list
  final List<String> posts = List.generate(12, (i) => "post_$i");

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile picture
        Container(
          height: 220,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Icon(Icons.person, size: 100, color: Colors.white),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "@$username",
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
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
                      )
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
                    child: const Icon(Icons.motorcycle, size: 120, color: Colors.black),
                  ),
                ),

                const SizedBox(height: 12),

                // Posts grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}