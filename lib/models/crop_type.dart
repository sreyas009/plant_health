class CropType {
  final String cropId;
  final String cropType;

  CropType({required this.cropId, required this.cropType});

  factory CropType.fromJson(Map<String, dynamic> json) {
    return CropType(
      cropId: json['cropId'] as String,
      cropType: json['cropType'] as String,
    );
  }
}
