import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../models/plant_health_record.dart';

class ApiService {
  static const String baseUrl = 'https://api.agricentral.io/api/';
  static const String _imageBase = 'https://blobstorage.farmfuture.io/';

  static String _appendImagePath(String rawPath) {
    if (rawPath.isEmpty) return '';
    if (rawPath.startsWith('http')) return rawPath;
    return '$_imageBase$rawPath';
  }

  static Future<List<PlantHealthRecord>> fetchPlantHealthData() async {
    final uri = Uri.parse('${baseUrl}Chat/GetPlantHealthData');
    debugPrint('GET $uri');
    final response = await http.get(uri);
    debugPrint('Response(${response.statusCode}): ${response.body}');
    if (response.statusCode != 200) {
      throw HttpException('Remote list failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as List<dynamic>;
    return decoded.whereType<Map<String, dynamic>>().map((json) {
      final record = PlantHealthRecord.fromJson(json);
      return PlantHealthRecord(
        guid: record.guid,
        label: record.label,
        ndvi: record.ndvi,
        brix: record.brix,
        dateTime: record.dateTime,
        imageUrl: _appendImagePath(record.imageUrl),
      );
    }).toList();
  }

  static Future<PlantHealthRecord> addPlantHealthData({
    required int label,
    double? ndvi,
    double? brix,
    required String imagePath,
  }) async {
    final uri = Uri.parse('${baseUrl}Chat/AddPlantHealthData');
    debugPrint('POST $uri');
    final recordTime = DateTime.now().toUtc().toIso8601String();
    final imageName = p.basename(imagePath);
    final payload = {
      'label': label,
      'ndvi': ndvi ?? 0,
      'brix': brix ?? 0,
      'recordDateTime': recordTime,
      'imageName': imageName,
    };
    debugPrint('POST $uri body: ${jsonEncode(payload)}, imageName: $imageName');

    final request = http.MultipartRequest('POST', uri)
      ..fields['request'] = jsonEncode(payload);

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);
    debugPrint('Response(${response.statusCode}): ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException('Upload failed (${response.statusCode})');
    }

    // final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final record = PlantHealthRecord.fromJson(payload);
    return PlantHealthRecord(
      guid: record.guid,
      label: record.label,
      ndvi: record.ndvi,
      brix: record.brix,
      dateTime: record.dateTime,
      imageUrl: _appendImagePath(record.imageUrl),
    );
  }
}
