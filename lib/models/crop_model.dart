// halkan soo dhig koodhkaaga Dart ee faylka lib/models/crop_model.dart
class Crop {
  final int? id;
  final String name;
  final String status;
  final String? image;
  final int? userId;
  final int fieldId; // Ku dar kan

  Crop({
    this.id,
    required this.name,
    required this.status,
    this.image,
    this.userId,
    required this.fieldId, // Ku dar kan
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      image: json['image'],
      userId: json['user_id'],
      fieldId: json['field_id'] ?? 0, // Ku dar kan
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'image': image,
      'user_id': userId,
      'field_id': fieldId, // Ku dar kan
    };
  }
}
