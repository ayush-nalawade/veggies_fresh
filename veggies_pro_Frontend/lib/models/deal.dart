import 'product.dart';

class Deal {
  final Product product;
  final int discountPercent;
  final double dealPrice;
  final double originalPrice;
  final DateTime dealEndsAt;

  Deal({
    required this.product,
    required this.discountPercent,
    required this.dealPrice,
    required this.originalPrice,
    required this.dealEndsAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      product: Product.fromJson(json),
      discountPercent: (json['discountPercent'] as num).toInt(),
      dealPrice: (json['dealPrice'] as num).toDouble(),
      originalPrice: (json['originalPrice'] as num).toDouble(),
      dealEndsAt: DateTime.parse(json['dealEndsAt']).toLocal(),
    );
  }
}
