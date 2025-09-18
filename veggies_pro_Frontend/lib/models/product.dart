class UnitPrice {
  final String unit;
  final double step;
  final double baseQty;
  final double price;
  final double? compareAt;
  final double stock;

  UnitPrice({
    required this.unit,
    required this.step,
    required this.baseQty,
    required this.price,
    this.compareAt,
    required this.stock,
  });

  factory UnitPrice.fromJson(Map<String, dynamic> json) {
    return UnitPrice(
      unit: json['unit'],
      step: (json['step'] + 0.0),
      baseQty: (json['baseQty'] + 0.0),
      price: (json['price'] + 0.0),
      compareAt: json['compareAt']?.toDouble(),
      stock: (json['stock'] + 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit': unit,
      'step': step,
      'baseQty': baseQty,
      'price': price,
      'compareAt': compareAt,
      'stock': stock,
    };
  }

  double calculatePrice(double quantity) {
    return double.parse(((quantity / baseQty) * price).toStringAsFixed(2));
  }
}

class Category {
  final String id;
  final String name;
  final String? iconUrl;
  final int sort;
  final bool isActive;

  Category({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.sort,
    required this.isActive,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      iconUrl: json['iconUrl'],
      sort: json['sort'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'sort': sort,
      'isActive': isActive,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String slug;
  final String categoryId;
  final List<String> images;
  final String? description;
  final List<UnitPrice> unitPrices;
  final double? rating;
  final bool isActive;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.categoryId,
    required this.images,
    this.description,
    required this.unitPrices,
    this.rating,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      slug: json['slug'],
      categoryId: json['categoryId']?['_id'] ?? json['categoryId'],
      images: List<String>.from(json['images'] ?? []),
      description: json['description'],
      unitPrices: (json['unitPrices'] as List<dynamic>)
          .map((unitPrice) => UnitPrice.fromJson(unitPrice))
          .toList(),
      rating: json['rating']?.toDouble(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'categoryId': categoryId,
      'images': images,
      'description': description,
      'unitPrices': unitPrices.map((unitPrice) => unitPrice.toJson()).toList(),
      'rating': rating,
      'isActive': isActive,
    };
  }

  String get firstImage => images.isNotEmpty ? images.first : '';
  
  double get minPrice {
    if (unitPrices.isEmpty) return 0.0;
    return unitPrices.map((up) => up.price).reduce((a, b) => a < b ? a : b);
  }
}
