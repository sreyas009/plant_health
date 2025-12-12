import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/plant_health_record.dart';
import '../models/saved_image.dart';
import '../providers/image_provider.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Future<List<PlantHealthRecord>>? _remoteFuture;

  @override
  void initState() {
    super.initState();
    _remoteFuture = ApiService.fetchPlantHealthData();
  }

  void _refreshRemote() {
    setState(() {
      _remoteFuture = ApiService.fetchPlantHealthData();
    });
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade700,
      ),
    );
  }

  Future<void> _uploadLocalImage(SavedImage img) async {
    final store = Provider.of<ImageStore>(context, listen: false);
    final labelValue = int.tryParse(img.label) ?? 0;
    _showSnack("Uploading ${img.label} to cloud...", isError: false);
    try {
      await ApiService.addPlantHealthData(
        label: labelValue,
        ndvi: img.ndvi,
        brix: img.brix,
        imagePath: img.path,
      );
      await store.removeImage(img);
      _showSnack("Uploaded ${img.label} successfully.", isError: false);
      _refreshRemote();
    } catch (_) {
      _showSnack("Upload failed for ${img.label}.", isError: true);
    }
  }

  Future<void> _deleteLocalImage(SavedImage img) async {
    final store = Provider.of<ImageStore>(context, listen: false);
    await store.removeImage(img);
    _showSnack("Local image ${img.label} deleted.", isError: false);
  }

  String _formatDateTime(DateTime date) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day;
    final suffix = (day % 100 >= 11 && day % 100 <= 13)
        ? 'th'
        : (day % 10 == 1
              ? 'st'
              : day % 10 == 2
              ? 'nd'
              : day % 10 == 3
              ? 'rd'
              : 'th');
    final month = monthNames[date.month - 1];
    final hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$day$suffix $month ${date.year} • $hour12:$minute $period';
  }

  Widget _buildRemoteCard(PlantHealthRecord record) {
    final theme = Theme.of(context);
    final brixLabel = record.brix.toStringAsFixed(1);
    final ndviLabel = record.ndvi.toStringAsFixed(2);
    final parsedDate = _formatDateTime(record.dateTime.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: record.imageUrl.isEmpty
                ? Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported),
                  )
                : Image.network(
                    record.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Label ${record.label}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Brix $brixLabel  |  NDVI $ndviLabel",
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  parsedDate,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteSection(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Shared Library",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Verified captures stored in the cloud for your team.",
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _refreshRemote,
                  icon: const Icon(Icons.refresh),
                  tooltip: "Refresh shared library",
                ),
              ],
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<PlantHealthRecord>>(
              future: _remoteFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox(
                    height: 80,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text(
                    "Unable to load cloud records.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.redAccent,
                    ),
                  );
                }

                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return Text(
                    "No shared records available yet.",
                    style: theme.textTheme.bodySmall,
                  );
                }

                return Column(
                  children: records
                      .map((record) => _buildRemoteCard(record))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalCard(SavedImage img) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    "Label ${img.label}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    img.text,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (img.brix != null || img.ndvi != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (img.brix != null)
                            Chip(
                              label: Text(
                                "BRIX ${img.brix!.toStringAsFixed(1)}",
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                            ),
                          if (img.ndvi != null)
                            Chip(
                              label: Text(
                                "NDVI ${img.ndvi!.toStringAsFixed(2)}",
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => _uploadLocalImage(img),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        tooltip: "Upload to cloud",
                      ),
                      IconButton(
                        onPressed: () => _deleteLocalImage(img),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: "Delete local entry",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalSection(BuildContext context, List<SavedImage> images) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pending Uploads",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${images.length} stored locally",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              "These captures live only on this device until you upload them.",
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (images.isEmpty)
              Text(
                "No local captures awaiting upload.",
                style: theme.textTheme.bodySmall,
              )
            else
              Column(
                children: images
                    .map(
                      (img) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildLocalCard(img),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = Provider.of<ImageStore>(context).images;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildRemoteSection(context),
        const SizedBox(height: 12),
        _buildLocalSection(context, images),
      ],
    );
  }
}
