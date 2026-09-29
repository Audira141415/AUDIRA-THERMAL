class Product {
  final int? id;
  final String? code;
  final String name;
  final double unitPrice;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    this.code,
    required this.name,
    required this.unitPrice,
    this.category = 'Umum',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Product copyWith({
    int? id,
    String? code,
    String? name,
    double? unitPrice,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'unit_price': unitPrice,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      code: map['code'] as String?,
      name: map['name'] as String? ?? '',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Umum',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
