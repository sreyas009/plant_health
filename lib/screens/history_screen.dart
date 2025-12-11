import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/image_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  String _formatReading(double value) {
    final truncated = value.truncate();
    if (value == truncated.toDouble()) {
      return truncated.toString();
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final images = Provider.of<ImageStore>(context).images;
    final theme = Theme.of(context);

    if (images.isEmpty) {
      return Center(
        child: Text(
          "No saved samples yet",
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: images.length,
      itemBuilder: (_, i) {
        final img = images[i];
        final chips = <Widget>[];
        if (img.brix != null) {
          chips.add(
            Chip(
              label: Text("BRIX ${_formatReading(img.brix!)}"),
              backgroundColor: theme.colorScheme.primaryContainer,
            ),
          );
        }
        if (img.ndvi != null) {
          chips.add(
            Chip(
              label: Text("NDVI ${_formatReading(img.ndvi!)}"),
              backgroundColor: theme.colorScheme.secondaryContainer,
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(img.path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Label • ${img.label}",
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        img.text,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: chips,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
