class PlantHealthRecord {
  final String guid;
  final int label;
  final double ndvi;
  final double brix;
  final DateTime dateTime;
  final String imageUrl;

  PlantHealthRecord({
    required this.guid,
    required this.label,
    required this.ndvi,
    required this.brix,
    required this.dateTime,
    required this.imageUrl,
  });

  factory PlantHealthRecord.fromJson(Map<String, dynamic> json) {
    final rawImage = json['imageUrl']?.toString() ?? '';
    return PlantHealthRecord(
      guid: json['guid']?.toString() ?? '',
      label: int.tryParse(json['label']?.toString() ?? '') ?? 0,
      ndvi: double.tryParse(json['ndvi']?.toString() ?? '') ?? 0,
      brix: double.tryParse(json['brix']?.toString() ?? '') ?? 0,
      dateTime:
          DateTime.tryParse(json['dateTimeValue']?.toString() ?? '') ??
          DateTime.now(),
      imageUrl: rawImage,
    );
  }
}
