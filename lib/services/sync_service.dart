import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'database_helper.dart';

class SyncService {
  static Future<void> addToQueue({
    required String cropTypeId,
    required String type,
    String? subtype,
    required String imagePath,
  }) async {
    final request = {
      'cropTypeId': cropTypeId,
      'type': type,
      'subtype': subtype,
      'imagePath': imagePath,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await DatabaseHelper.instance.insertRequest(request);
    debugPrint('Added request to offline queue: $request');
  }

  static Future<void> processQueue() async {
    debugPrint('Processing offline queue...');
    final requests = await DatabaseHelper.instance.getReferencedRequests();

    if (requests.isEmpty) {
      debugPrint('Offline queue is empty.');
      return;
    }

    for (var request in requests) {
      final id = request['id'] as int;
      final cropTypeId = request['cropTypeId'] as String;
      final type = request['type'] as String;
      final subtype = request['subtype'] as String?;
      final imagePath = request['imagePath'] as String;

      try {
        debugPrint('Attempting to sync request ID: $id');
        await ApiService.uploadDataCollection(
          cropTypeId: cropTypeId,
          type: type,
          subtype: subtype,
          imagePath: imagePath,
        );

        await DatabaseHelper.instance.deleteRequest(id);
        debugPrint('Successfully synced and removed request ID: $id');
      } catch (e) {
        debugPrint('Failed to sync request ID: $id. Error: $e');
        // Stop processing if one fails (assuming network issue),
        // to preserve order and retry later.
        break;
      }
    }
  }
}
