/**
 * world_news_bar.dart
 *
 * File-level Dartdoc:
 * A small horizontal ticker widget that displays brief world news headlines.
 * It accepts a list of headline strings and an optional tap callback for items.
 */
import 'package:flutter/material.dart';

/**
 * Displays a horizontal list of short news items with a leading world icon.
 *
 * @param newsItems List of strings shown as headlines.
 * @param onTapHeadline Optional callback invoked with the tapped headline.
 */
class WorldNewsBar extends StatelessWidget {
  final List<String> newsItems;
  final void Function(String)? onTapHeadline;

  const WorldNewsBar({Key? key, required this.newsItems, this.onTapHeadline}) : super(key: key);

  /**
   * Build the horizontal news bar UI using a ListView to allow scrolling.
   *
   * @param context BuildContext used to construct widgets.
   * @return Widget The rendered news bar.
   */
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.public, color: Colors.white70),
          const SizedBox(width: 8),
          const Text('World‑News', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: newsItems.length,
              itemBuilder: (context, idx) {
                final txt = newsItems[idx];
                return GestureDetector(
                  onTap: () => onTapHeadline?.call(txt),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                    child: Center(child: Text(txt, style: const TextStyle(color: Colors.white70), overflow: TextOverflow.ellipsis)),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
            ),
          ),
        ],
      ),
    );
  }
}