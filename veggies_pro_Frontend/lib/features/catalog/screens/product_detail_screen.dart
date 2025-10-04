import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/dio_client.dart';
import '../../../models/product.dart';
import '../../../models/cart.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _isLoading = true;
  int _selectedUnitIndex = 0;
  double _quantity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final response = await DioClient().dio.get('/products/${widget.productId}');
      if (response.statusCode == 200) {
        setState(() {
          _product = Product.fromJson(response.data['data']);
          if (_product!.unitPrices.isNotEmpty) {
            _selectedUnitIndex = 0; // Always select first unit
            _quantity = _product!.unitPrices[_selectedUnitIndex].step;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load product: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToCart() async {
    if (_product == null || !mounted) return;

    try {
      final selectedUnit = _product!.unitPrices[_selectedUnitIndex];
      final response = await DioClient().dio.post('/cart/items', data: {
        'productId': _product!.id,
        'unit': selectedUnit.unit,
        'qty': _quantity,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          // onPressed: () => context.go('/products/${_product!.categoryId}'),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      Container(
                        height: 300,
                        width: double.infinity,
                        child: _product!.firstImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: _product!.firstImage,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.image, size: 100),
                              )
                            : const Icon(Icons.image, size: 100),
                      ),
                      
                      // Product Info
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (_product!.rating != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text('${_product!.rating!.toStringAsFixed(1)}'),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            if (_product!.description != null) ...[
                              Text(
                                _product!.description!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            // Unit Display (Single Unit)
                            Text(
                              'Unit',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _getUnitIcon(),
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _getUnitText(),
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Quantity Selector
                            _buildQuantitySelector(),
                            const SizedBox(height: 24),
                            
                            // Price Display
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Price',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      Text(
                                        '₹${_calculatePrice().toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addToCart,
                                    icon: const Icon(Icons.add_shopping_cart),
                                    label: const Text('Add to Cart'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildQuantitySelector() {
    final selectedUnit = _product!.unitPrices[_selectedUnitIndex];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  _quantity = (_quantity - selectedUnit.step).clamp(selectedUnit.step, 100.0);
                });
              },
              icon: const Icon(Icons.remove),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _getQuantityDisplayText(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _quantity += selectedUnit.step;
                });
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  double _calculatePrice() {
    if (_product == null || _product!.unitPrices.isEmpty) return 0.0;
    final selectedUnit = _product!.unitPrices[_selectedUnitIndex];
    return selectedUnit.calculatePrice(_quantity);
  }

  IconData _getUnitIcon() {
    if (_product == null || _product!.unitPrices.isEmpty) return Icons.shopping_bag;
    
    final unit = _product!.unitPrices[_selectedUnitIndex].unit.toLowerCase();
    if (unit.contains('kg') || unit.contains('g') || unit.contains('weight')) {
      return Icons.scale;
    } else {
      return Icons.shopping_bag;
    }
  }

  String _getUnitText() {
    if (_product == null || _product!.unitPrices.isEmpty) return 'Unit';

    final unitPrice = _product!.unitPrices[_selectedUnitIndex];
    final unit = unitPrice.unit.toLowerCase();

    if (unit.contains('kg') || unit.contains('g') || unit.contains('weight')) {
      return '${unitPrice.baseQty} kg';
    } else {
      return '${unitPrice.baseQty} pcs';
    }
  }

  String _getQuantityDisplayText() {
    if (_quantity < 1.0 && (_product!.unitPrices[_selectedUnitIndex].unit.toLowerCase().contains('kg'))) {
      // Convert kg to grams for display when quantity is less than 1 kg
      final grams = (_quantity * 1000).toInt();
      return '${grams} gm';
    } else {
      // Show normal display for other cases
      return '${_quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 2)} ${_product!.unitPrices[_selectedUnitIndex].unit}';
    }
  }
}
