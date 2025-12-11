import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/saved_image.dart';

class ImageStore extends ChangeNotifier {
  final List<SavedImage> _images = [];

  ImageStore() {
    _load();
  }

  List<SavedImage> get images => List.unmodifiable(_images);

  Future<void> addImage(SavedImage img) async {
    _images.add(img);
    await _save();
    notifyListeners();
  }

  int get nextLabel => _images.length + 1;

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
      final decoded = jsonDecode(contents) as List<dynamic>;
      _images
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(
            (json) => SavedImage.fromJson(json),
          ),
        );
      notifyListeners();
    } catch (_) {
      // Ignore load errors so the history stays empty.
    }
  }

  Future<void> _save() async {
    final file = await _storageFile;
    final payload = jsonEncode(_images.map((img) => img.toJson()).toList());
    await file.writeAsString(payload);
  }
}
