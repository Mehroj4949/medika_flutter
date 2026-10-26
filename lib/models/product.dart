class Product {
  final String id;
  final String brand;
  final String model;
  final String category;
  final String stock;
  final String image;
  final String description;
  final List<String> benefits;
  final Map<String, String> specs;
  final bool isNew;
  final bool imageVerified;

  const Product({
    required this.id,
    required this.brand,
    required this.model,
    required this.category,
    required this.stock,
    required this.image,
    required this.description,
    required this.benefits,
    required this.specs,
    this.isNew = false,
    this.imageVerified = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: '${json['id'] ?? ''}',
      brand: '${json['brand'] ?? ''}',
      model: '${json['model'] ?? ''}',
      category: '${json['cat'] ?? json['category'] ?? ''}',
      stock: '${json['stock'] ?? 'Под заказ'}',
      image: '${json['image'] ?? ''}',
      description: '${json['desc'] ?? json['description'] ?? ''}',
      benefits: (json['benefits'] as List? ?? const []).map((e) => '$e').where((e) => e.isNotEmpty).toList(),
      specs: _stringMap(json['specs']),
      isNew: json['isNew'] == true,
      imageVerified: json['imageVerified'] == true,
    );
  }

  factory Product.fromCompactRow(List<dynamic> row) {
    final benefitText = row.length > 6 ? '${row[6]}' : '';
    final specText = row.length > 7 ? '${row[7]}' : '';
    return Product(
      id: row.isNotEmpty ? '${row[0]}' : '',
      brand: row.length > 1 ? '${row[1]}' : '',
      model: row.length > 2 ? '${row[2]}' : '',
      category: row.length > 3 ? '${row[3]}' : '',
      image: row.length > 4 ? '${row[4]}' : '',
      description: row.length > 5 ? '${row[5]}' : '',
      stock: 'Под заказ',
      benefits: benefitText.isEmpty ? const [] : benefitText.split('¦').where((e) => e.trim().isNotEmpty).toList(),
      specs: _decodeCompactSpecs(specText),
    );
  }

  Product copyWith({
    String? stock,
    String? image,
    Map<String, String>? specs,
    bool? imageVerified,
  }) {
    return Product(
      id: id,
      brand: brand,
      model: model,
      category: category,
      stock: stock ?? this.stock,
      image: image ?? this.image,
      description: description,
      benefits: benefits,
      specs: specs ?? this.specs,
      isNew: isNew,
      imageVerified: imageVerified ?? this.imageVerified,
    );
  }

  String get searchText => [brand, model, category, description, ...benefits, ...specs.keys, ...specs.values].join(' ').toLowerCase();

  static Map<String, String> _stringMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map((k, v) => MapEntry('$k', '$v'));
  }

  static Map<String, String> _decodeCompactSpecs(String input) {
    final out = <String, String>{};
    for (final pair in input.split('¦')) {
      final index = pair.indexOf('≈');
      if (index <= 0) continue;
      out[pair.substring(0, index).trim()] = pair.substring(index + 1).trim();
    }
    return out;
  }
}
