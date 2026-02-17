import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'database_helper.dart';

import '../models/plant_health_record.dart';

import '../models/crop_type.dart';
import '../models/disease_type.dart';

class ApiService {
  static const String baseUrl = 'https://api.agricentral.io/api/';
  static const String farmFutureBaseUrl = 'https://api.farmfuture.io/api/';
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

  static Future<List<CropType>> getCropsData() async {
    final uri = Uri.parse('${farmFutureBaseUrl}StaticData/GetCropsData');
    debugPrint('GET $uri');

    try {
      final response = await http.get(uri);
      debugPrint('Response(${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        // Cache the successful response
        await DatabaseHelper.instance.cacheResponse(
          uri.toString(),
          response.body,
        );

        final json = jsonDecode(response.body);
        if (json['succeeded'] == true) {
          final List<dynamic> data = json['data'];
          return data.map((e) => CropType.fromJson(e)).toList();
        } else {
          throw HttpException('Failed to fetch crops data: ${json['message']}');
        }
      }
    } catch (e) {
      debugPrint('Network error, trying cache for $uri: $e');
    }

    // Fallback to cache
    final cachedBody = await DatabaseHelper.instance.getCachedResponse(
      uri.toString(),
    );
    if (cachedBody != null) {
      debugPrint('Loaded crops from cache');
      final json = jsonDecode(cachedBody);
      if (json['succeeded'] == true) {
        final List<dynamic> data = json['data'];
        return data.map((e) => CropType.fromJson(e)).toList();
      }
    }

    throw HttpException('Failed to fetch crops data and no cache available');
  }

  static Future<List<DiseaseType>> getDiseases() async {
    final uri = Uri.parse('${farmFutureBaseUrl}StaticData/GetDiseases');
    debugPrint('GET $uri');

    try {
      final response = await http.get(uri);
      debugPrint('Response(${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        // Cache successful response
        await DatabaseHelper.instance.cacheResponse(
          uri.toString(),
          response.body,
        );

        final json = jsonDecode(response.body);
        if (json['succeeded'] == true) {
          final List<dynamic> data = json['data'];
          return data.map((e) => DiseaseType.fromJson(e)).toList();
        } else {
          throw HttpException(
            'Failed to fetch diseases data: ${json['message']}',
          );
        }
      }
    } catch (e) {
      debugPrint('Network error, trying cache for $uri: $e');
    }

    // Fallback to cache
    final cachedBody = await DatabaseHelper.instance.getCachedResponse(
      uri.toString(),
    );
    if (cachedBody != null) {
      debugPrint('Loaded diseases from cache');
      final json = jsonDecode(cachedBody);
      if (json['succeeded'] == true) {
        final List<dynamic> data = json['data'];
        return data.map((e) => DiseaseType.fromJson(e)).toList();
      }
    }

    throw HttpException('Failed to fetch diseases data and no cache available');
  }

  static Future<List<DiseaseType>> getNutrients() async {
    final uri = Uri.parse('${farmFutureBaseUrl}StaticData/GetNutrients');
    debugPrint('GET $uri');

    try {
      final response = await http.get(uri);
      debugPrint('Response(${response.statusCode}): ${response.body}');

      if (response.statusCode == 200) {
        // Cache successful response
        await DatabaseHelper.instance.cacheResponse(
          uri.toString(),
          response.body,
        );

        final json = jsonDecode(response.body);
        if (json['succeeded'] == true) {
          final List<dynamic> data = json['data'];
          return data.map((e) => DiseaseType.fromJson(e)).toList();
        } else {
          throw HttpException(
            'Failed to fetch nutrients data: ${json['message']}',
          );
        }
      }
    } catch (e) {
      debugPrint('Network error, trying cache for $uri: $e');
    }

    // Fallback to cache
    final cachedBody = await DatabaseHelper.instance.getCachedResponse(
      uri.toString(),
    );
    if (cachedBody != null) {
      debugPrint('Loaded nutrients from cache');
      final json = jsonDecode(cachedBody);
      if (json['succeeded'] == true) {
        final List<dynamic> data = json['data'];
        return data.map((e) => DiseaseType.fromJson(e)).toList();
      }
    }

    throw HttpException(
      'Failed to fetch nutrients data and no cache available',
    );
  }

  static Future<void> uploadDataCollection({
    required String cropTypeId,
    required String type,
    String? subtype,
    required String imagePath,
  }) async {
    final uri = Uri.parse('${farmFutureBaseUrl}MLDataCollection/upload');
    debugPrint('POST $uri');

    final request = http.MultipartRequest('POST', uri);

    final payload = {
      'cropTypeId': cropTypeId,
      'type': type,
      'subtype': subtype,
    };

    // The API expects the metadata in a field named 'request'
    request.fields['request'] = jsonEncode(payload);

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    debugPrint('Request fields: ${request.fields}');

    final streamResponse = await request.send();
    final response = await http.Response.fromStream(streamResponse);
    debugPrint('Response(${response.statusCode}): ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException('Upload failed (${response.statusCode})');
    }
  }
}
