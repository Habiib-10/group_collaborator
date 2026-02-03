class Field {
  final int? id;
  final String name;
  final String location;
  final String size;
  final String status;
  final double price; // Waa inuu double yahay
  final int userId;

  Field({
    this.id,
    required this.name,
    required this.location,
    required this.size,
    required this.status,
    required this.price,
    required this.userId,
  });

  // Halkan waa meesha ugu muhiimsan (Parsing)
  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'] ?? '',
      location: json['location'] ?? '',
      size: json['size'] ?? '',
      status: json['status'] ?? 'Active',
      // tryParse waxay xaqiijinaysaa in xogta String-ka ah loo beddelo lambar
      price: json['price'] != null ? double.parse(json['price'].toString()) : 0.0,
      userId: json['user_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'size': size,
      'status': status,
      'price': price,
      'user_id': userId,
    };
  }
}