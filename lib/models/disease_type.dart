class DiseaseType {
  final String id;
  final String name;
  final String? image;
  final String? details;
  final List<String>? symptoms;
  final List<String>? remedies;
  final List<String>? preventiveMeasures;
  final String? cause;
  final String? categoryType;
  final String? cropId;

  DiseaseType({
    required this.id,
    required this.name,
    this.image,
    this.details,
    this.symptoms,
    this.remedies,
    this.preventiveMeasures,
    this.cause,
    this.categoryType,
    this.cropId,
  });

  factory DiseaseType.fromJson(Map<String, dynamic> json) {
    return DiseaseType(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      details: json['details'] as String?,
      symptoms: (json['symptoms'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      remedies: (json['remedies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      preventiveMeasures: (json['preventiveMeasures'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      cause: json['cause'] as String?,
      categoryType: json['categoryType'] as String?,
      cropId: json['cropId'] as String?,
    );
  }
}
