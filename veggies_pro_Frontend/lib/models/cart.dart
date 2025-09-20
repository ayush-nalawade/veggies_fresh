import 'product.dart';

class CartItem {
  final String productId;
  final String name;
  final String image;
  final String unit;
  final double qty;
  final double unitPrice;
  final double price;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    required this.price,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['productId']?.toString() ?? (json['productId'] is Map ? json['productId']['_id']?.toString() : '') ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'image': image,
      'unit': unit,
      'qty': qty,
      'unitPrice': unitPrice,
      'price': price,
    };
  }

  CartItem copyWith({
    String? productId,
    String? name,
    String? image,
    String? unit,
    double? qty,
    double? unitPrice,
    double? price,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      unit: unit ?? this.unit,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
      price: price ?? this.price,
    );
  }
}

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? (json['userId'] is Map ? json['userId']['_id']?.toString() : '') ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      subtotal: (json['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
    };
  }

  int get itemCount => items.fold(0, (sum, item) => sum + item.qty.round());
}
