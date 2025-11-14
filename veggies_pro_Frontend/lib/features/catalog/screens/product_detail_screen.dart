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
  
  // Check if product has tiered weight pricing
  bool get _hasTieredWeightPricing {
    if (_product == null) return false;
    final weightTiers = _product!.unitPrices.where((up) => up.unit == 'g' || up.unit == 'kg').toList();
    return weightTiers.length > 1;
  }
  
  // Get the step increment (in grams for weight products)
  double get _stepIncrement {
    if (!_hasTieredWeightPricing || _product == null) {
      return _product?.unitPrices[_selectedUnitIndex].step ?? 1.0;
    }
    return 250.0; // 250gm for weight-based products
  }

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
            // For tiered weight products, start with 250gm
            final weightTiers = _product!.unitPrices.where((up) => up.unit == 'g' || up.unit == 'kg').toList();
            if (weightTiers.length > 1) {
              _quantity = 250.0; // Start with 250gm
            } else {
              _quantity = _product!.unitPrices[_selectedUnitIndex].step;
            }
          }
        });
      }
    } catch (e) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (mounted && messenger != null) {
        messenger.showSnackBar(
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
      // For tiered weight products, always use 'g' unit
      String unit;
      double qty;
      
      if (_hasTieredWeightPricing) {
        unit = 'g';
        qty = _quantity; // Already in grams
      } else {
        final selectedUnit = _product!.unitPrices[_selectedUnitIndex];
        unit = selectedUnit.unit;
        qty = _quantity;
      }
      
      final response = await DioClient().dio.post('/cart/items', data: {
        'productId': _product!.id,
        'unit': unit,
        'qty': qty,
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;

        // Format quantity display for snackbar
        String qtyDisplay;
        if (_hasTieredWeightPricing) {
          if (_quantity >= 1000) {
            qtyDisplay = '${(_quantity / 1000).toStringAsFixed(2)} kg';
          } else {
            qtyDisplay = '${_quantity.toInt()} gm';
          }
        } else {
          qtyDisplay = '${_quantity} $unit';
        }

        messenger.clearSnackBars();
        if (!mounted) return;

        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Added $qtyDisplay to cart!',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Extract user-friendly error message
      String errorMessage = 'Item already in cart you can change the quantity';
      
      if (e.toString().contains('Insufficient stock')) {
        errorMessage = 'Insufficient stock available for this quantity';
      } else if (e.toString().contains('Product not found')) {
        errorMessage = 'This product is no longer available';
      } else if (e.toString().contains('Invalid unit')) {
        errorMessage = 'Invalid unit selected';
      }
      
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      messenger.clearSnackBars();

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
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
                            
                            // Pricing Tiers Display (for tiered weight products)
                            if (_hasTieredWeightPricing) ...[
                              _buildPricingTiersDisplay(),
                              const SizedBox(height: 16),
                            ],
                            
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
                  if (_hasTieredWeightPricing) {
                    _quantity = (_quantity - _stepIncrement).clamp(_stepIncrement, 100000.0);
                  } else {
                    final selectedUnit = _product!.unitPrices[_selectedUnitIndex];
                    _quantity = (_quantity - selectedUnit.step).clamp(selectedUnit.step, 100.0);
                  }
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
                  if (_hasTieredWeightPricing) {
                    _quantity += _stepIncrement;
                  } else {
                    final selectedUnit = _product!.unitPrices[_selectedUnitIndex];
                    _quantity += selectedUnit.step;
                  }
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
    
    // Use tiered pricing for weight products
    if (_hasTieredWeightPricing) {
      return UnitPrice.calculateTieredPrice(_quantity, _product!.unitPrices);
    }
    
    // Regular pricing for non-tiered products
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
    if (_hasTieredWeightPricing) {
      // For tiered weight products, always show in gm or kg
      if (_quantity >= 1000) {
        return '${(_quantity / 1000).toStringAsFixed(2)} kg';
      } else {
        return '${_quantity.toInt()} gm';
      }
    } else if (_quantity < 1.0 && (_product!.unitPrices[_selectedUnitIndex].unit.toLowerCase().contains('kg'))) {
      // Convert kg to grams for display when quantity is less than 1 kg
      final grams = (_quantity * 1000).toInt();
      return '${grams} gm';
    } else {
      // Show normal display for other cases
      return '${_quantity.toStringAsFixed(_quantity % 1 == 0 ? 0 : 2)} ${_product!.unitPrices[_selectedUnitIndex].unit}';
    }
  }

  Widget _buildPricingTiersDisplay() {
    // Get weight tiers
    final weightTiers = _product!.unitPrices
        .where((up) => up.unit == 'g' || up.unit == 'kg')
        .toList();

    if (weightTiers.isEmpty) return const SizedBox.shrink();

    // Find 250gm and 1kg tiers
    final tier250 = weightTiers.firstWhere(
      (t) => t.baseQty == 250, 
      orElse: () => weightTiers.first
    );
    final tier1kg = weightTiers.firstWhere(
      (t) => t.baseQty == 1000, 
      orElse: () => weightTiers.last
    );
    
    // Calculate what 1kg would cost at 250gm pricing (4 × 250gm price)
    final regularPrice1kg = tier250.price * 4;
    final actualPrice1kg = tier1kg.price;
    final savings = regularPrice1kg - actualPrice1kg;
    final savingsPercent = ((savings / regularPrice1kg) * 100).round();

    // Only show if there's actual savings
    if (savings <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade50,
            Colors.green.shade100.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Price on 1 kg',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '₹${regularPrice1kg.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${actualPrice1kg.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Save $savingsPercent%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}