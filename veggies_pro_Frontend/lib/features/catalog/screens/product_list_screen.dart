import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/dio_client.dart';
import '../../../models/product.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String categoryId;
  final String? categoryName;

  const ProductListScreen({super.key, required this.categoryId, this.categoryName});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  String _categoryName = '';

  @override
  void initState() {
    super.initState();
    _categoryName = widget.categoryName ?? '';
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await DioClient().dio.get('/products?category=${widget.categoryId}');
      if (response.statusCode == 200) {
        setState(() {
          _products = (response.data['data'] as List)
              .map((json) => Product.fromJson(json))
              .toList();
        });
        
        // If name wasn't passed, try to infer from nested category if available
        if (_categoryName.isEmpty && _products.isNotEmpty) {
          // Some responses may embed category object; try to read name if present
          final first = response.data['data'][0];
          final maybeCat = first['categoryId'];
          if (maybeCat is Map && maybeCat['name'] is String) {
            _categoryName = maybeCat['name'] as String;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryName.isNotEmpty ? _categoryName : 'Products'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,
              child: _products.isEmpty
                  ? const Center(
                      child: Text('No products found in this category'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.8, // Increased from 0.75 to give more height
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return _buildProductCard(product);
                      },
                    ),
            ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.go('/product/${product.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3, // Reduced from 4 to give more space to content
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.firstImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.firstImage,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.image, size: 32),
                        )
                      : const Icon(Icons.image, size: 32),
                ),
              ),
            ),
            Expanded(
              flex: 2, // Reduced from 3 but content is better organized
              child: Padding(
                padding: const EdgeInsets.all(8), // Increased padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // Slightly larger
                      ),
                      maxLines: 1, // Reduced to 1 line to save space
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
                    // Price and rating row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'From ₹${product.minPrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (product.rating != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 12, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(
                                product.rating!.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                      ],
                    ),
                    
                    const Spacer(), // This will push the button to the bottom
                    
                    // View button
                    SizedBox(
                      width: double.infinity,
                      height: 28, // Fixed height for button
                      child: ElevatedButton(
                        onPressed: () => context.go('/product/${product.id}'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                        ),
                        child: const Text('View', style: TextStyle(fontSize: 11)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}