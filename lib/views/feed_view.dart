import 'package:flutter/material.dart';

class FeedView extends StatefulWidget {
  final String username;
  final VoidCallback onProfileTap;

  const FeedView({super.key, required this.username, required this.onProfileTap});

  @override
  State<FeedView> createState() => _FeedViewState();
}

//state of the feed with it'S widgets - showing placeholders for now
class _FeedViewState extends State<FeedView> {
  final PageController _pageController = PageController(viewportFraction: 0.78);
  final List<String> _postImages = List.generate(
    5,
        (i) => 'https://picsum.photos/seed/moto$i/800/600', // placeholder images
  );

  final List<Map<String, String>> _news = List.generate(1, (i) {
    return {
      "title": "Title news #$i",
      "excerpt":
      "Some really interesting stuff happening right now. This is a short summary of the news item #$i.",
      "thumb": "https://picsum.photos/seed/news$i/200/140",
    };
  });

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  //function that calculates spacing of the page
  double _calculateScale(int index) {
    if (!_pageController.hasClients || _pageController.positions.isEmpty) return 1.0;
    final page = _pageController.page ?? _pageController.initialPage.toDouble();
    final diff = (page - index).abs();
    return (1 - (diff * 0.16)).clamp(0.82, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Title Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ride2gather",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    InkWell(
                      onTap: widget.onProfileTap,
                      child: const Icon(Icons.person_outline, size: 28),
                    ),
                  ],
                ),
              ),

              // Recent user posts (carousel view)
              SizedBox(
                height: 240,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _postImages.length,
                  itemBuilder: (context, index) {
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        final scale = _calculateScale(index);
                        final verticalOffset = (1 - scale) * 16;
                        return Transform.translate(
                          offset: Offset(0, verticalOffset),
                          child: Transform.scale(scale: scale, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              image: DecorationImage(
                                image: NetworkImage(_postImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.center,
                                  ),
                                ),
                                child: Text(
                                  "Post #$index",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // Recent messages from users
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Column(
                  children: List.generate(3, (idx) {
                    return Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                          title: const Text("message text here?"),
                          subtitle: const Text("short subtitle or metadata"),
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                      ],
                    );
                  }),
                ),
              ),

              const SizedBox(height: 8),

              // News feed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "News",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _news.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = _news[index];
                        return InkWell(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item["thumb"]!,
                                    width: size.width * 0.28,
                                    height: 78,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: size.width * 0.28,
                                      height: 78,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 36),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item["title"] ?? "No title",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item["excerpt"] ?? "",
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
