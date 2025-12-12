import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_image.dart';

class ImageStore extends ChangeNotifier {
  final List<SavedImage> _images = [];
  int _lastLabel = 0;

  ImageStore() {
    _load();
  }

  List<SavedImage> get images => List.unmodifiable(_images);

  Future<SavedImage> addImage(SavedImage img) async {
    _images.add(img);
    _lastLabel = max(_lastLabel, int.tryParse(img.label) ?? _lastLabel);
    await _save();
    notifyListeners();
    return img;
  }

  Future<void> removeImage(SavedImage img) async {
    final index = _images.indexWhere((current) => current.path == img.path);
    if (index == -1) return;

    final removed = _images.removeAt(index);
    await _save();
    notifyListeners();

    final localFile = File(removed.path);
    if (await localFile.exists()) {
      try {
        await localFile.delete();
      } catch (_) {
        // If file deletion fails, ignore.
      }
    }
  }

  int get nextLabel {
    final timestampLabel = _timestampLabel();
    return _lastLabel >= timestampLabel ? _lastLabel + 1 : timestampLabel;
  }

  int _timestampLabel() {
    final now = DateTime.now().toUtc();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    final millisecond = now.millisecond.toString().padLeft(3, '0');
    return int.parse('$year$month$day$hour$minute$second$millisecond');
  }

  Future<File> get _storageFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/history.json');
  }

  Future<void> _load() async {
    try {
      final file = await _storageFile;
      if (!file.existsSync()) return;
      final contents = await file.readAsString();
      if (contents.isEmpty) return;
      final decoded = jsonDecode(contents);
      List<dynamic> imageList = [];
      int persistedLabel = 0;

      if (decoded is Map) {
        persistedLabel = decoded['lastLabel'] is int
            ? decoded['lastLabel'] as int
            : int.tryParse(decoded['lastLabel']?.toString() ?? '') ?? 0;
        imageList = decoded['images'] is List
            ? decoded['images'] as List<dynamic>
            : [];
      } else if (decoded is List) {
        imageList = decoded;
      }

      final loaded = imageList
          .whereType<Map<String, dynamic>>()
          .map((json) => SavedImage.fromJson(json))
          .toList();

      _images
        ..clear()
        ..addAll(loaded);

      final maxLabelFromImages = _images
          .map((img) => int.tryParse(img.label) ?? 0)
          .fold(0, max);

      _lastLabel = max(persistedLabel, maxLabelFromImages);
      notifyListeners();
    } catch (_) {
      // Ignore load errors so the history stays empty.
    }
  }

  Future<void> _save() async {
    final file = await _storageFile;
    final payload = jsonEncode({
      'lastLabel': _lastLabel,
      'images': _images.map((img) => img.toJson()).toList(),
    });
    await file.writeAsString(payload);
  }
}
