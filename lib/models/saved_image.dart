class SavedImage {
  final String path;
  final String label;
  final String text;
  final double? brix;
  final double? ndvi;

  SavedImage({
    required this.path,
    required this.label,
    required this.text,
    this.brix,
    this.ndvi,
  });

  Map<String, dynamic> toJson() => {
    'path': path,
    'label': label,
    'text': text,
    'brix': brix,
    'ndvi': ndvi,
  };

  factory SavedImage.fromJson(Map<String, dynamic> json) => SavedImage(
    path: json['path'] as String,
    label: json['label'] as String,
    text: json['text'] as String,
    brix: json['brix'] != null ? (json['brix'] as num).toDouble() : null,
    ndvi: json['ndvi'] != null ? (json['ndvi'] as num).toDouble() : null,
  );
}
