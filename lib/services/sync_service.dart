import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'database_helper.dart';

class SyncResult {
  final int total;
  final int synced;
  final int failed;
  final int missingFiles;

  const SyncResult({
    required this.total,
    required this.synced,
    required this.failed,
    required this.missingFiles,
  });

  bool get isEmpty => total == 0;
}

class SyncService {
  static Future<void> addToQueue({
    required String cropTypeId,
    required String type,
    String? subtype,
    required String imagePath,
  }) async {
    final persistentImagePath = await _copyImageToOfflineStorage(imagePath);
    final request = {
      'cropTypeId': cropTypeId,
      'type': type,
      'subtype': subtype,
      'imagePath': persistentImagePath,
      'createdAt': DateTime.now().toIso8601String(),
      'uploaded': 0,
    };
    await DatabaseHelper.instance.insertRequest(request);
    debugPrint('Added request to offline queue: $request');
  }

  static Future<SyncResult> processQueue({Set<int>? onlyIds}) async {
    debugPrint('Processing offline queue...');
    final pendingRequests = await DatabaseHelper.instance.getPendingRequests();
    final requests = onlyIds == null
        ? pendingRequests
        : pendingRequests
              .where((request) => onlyIds.contains(request['id'] as int))
              .toList();

    if (requests.isEmpty) {
      debugPrint('Offline queue is empty.');
      return const SyncResult(total: 0, synced: 0, failed: 0, missingFiles: 0);
    }

    var synced = 0;
    var failed = 0;
    var missingFiles = 0;

    for (var request in requests) {
      final id = request['id'] as int;
      final cropTypeId = request['cropTypeId'] as String;
      final type = request['type'] as String;
      final subtype = request['subtype'] as String?;
      final imagePath = request['imagePath'] as String;

      try {
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          missingFiles++;
          debugPrint(
            'Skipped request ID $id because image file is missing: $imagePath',
          );
          continue;
        }

        debugPrint('Attempting to sync request ID: $id');
        await ApiService.uploadDataCollection(
          cropTypeId: cropTypeId,
          type: type,
          subtype: subtype,
          imagePath: imagePath,
        );

        await DatabaseHelper.instance.markUploaded(id);
        synced++;
        debugPrint(
          'Successfully synced and marked uploaded for request ID: $id',
        );
      } catch (e) {
        failed++;
        debugPrint('Failed to sync request ID: $id. Error: $e');
      }
    }

    return SyncResult(
      total: requests.length,
      synced: synced,
      failed: failed,
      missingFiles: missingFiles,
    );
  }

  static Future<String> _copyImageToOfflineStorage(String originalPath) async {
    final source = File(originalPath);
    if (!await source.exists()) {
      throw FileSystemException(
        'Image not found for offline queue',
        originalPath,
      );
    }

    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory(p.join(appDir.path, 'offline_queue_images'));
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }

    final baseName = p.basenameWithoutExtension(originalPath);
    final ext = p.extension(originalPath);
    final safeBaseName = baseName.isEmpty ? 'image' : baseName;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$safeBaseName$ext';
    final destinationPath = p.join(offlineDir.path, fileName);

    await source.copy(destinationPath);
    return destinationPath;
  }
}
