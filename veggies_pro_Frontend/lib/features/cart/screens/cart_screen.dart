import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/dio_client.dart';
import '../../../models/cart.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Cart? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final response = await DioClient().dio.get('/cart');
      if (response.statusCode == 200) {
        final responseData = response.data;
        print('Cart API Response: $responseData'); // Debug log
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final cartData = responseData['data'];
          print('Cart items: ${cartData['items']}'); // Debug log for items
          
          setState(() {
            _cart = Cart.fromJson(cartData);
          });
          
          // Debug log each item's productId
          for (var item in _cart!.items) {
            print('Cart item productId: ${item.productId} (type: ${item.productId.runtimeType})');
          }
        } else {
          // Handle empty cart response
          setState(() {
            _cart = Cart(
              id: '',
              userId: '',
              items: [],
              subtotal: 0.0,
            );
          });
        }
      }
    } catch (e) {
      print('Cart loading error: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateQuantity(String productId, double newQuantity) async {
    try {
      print('Updating quantity for productId: $productId, newQuantity: $newQuantity'); // Debug log
      
      // Round to 2 decimal places and ensure minimum quantity
      newQuantity = double.parse(newQuantity.toStringAsFixed(2));
      
      // If quantity is 0 or negative, show confirmation before removing
      if (newQuantity <= 0) {
        // Find the item name for confirmation dialog
        final item = _cart?.items.firstWhere(
          (item) => item.productId == productId,
          orElse: () => _cart!.items.first,
        );
        await _confirmAndRemoveItem(productId, item?.name ?? 'this item');
        return;
      }
      
      final response = await DioClient().dio.patch('/cart/items/$productId', data: {
        'qty': newQuantity,
      });

      if (!mounted) return;

      print('Update response: ${response.statusCode} - ${response.data}'); // Debug log
      if (response.statusCode == 200) {
        _loadCart(); // Reload cart silently
      }
    } catch (e) {
      print('Update quantity error: $e'); // Debug log
      if (!mounted) return;
      
      // Only show error messages, not success messages
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Failed to update quantity')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmAndRemoveItem(String productId, String productName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Item'),
          content: Text('Are you sure you want to remove "$productName" from your cart?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    // If not confirmed, return
    if (confirmed != true || !mounted) return;

    // Proceed with removal
    try {
      print('Removing item with productId: $productId'); // Debug log
      
      final response = await DioClient().dio.delete('/cart/items/$productId');

      if (!mounted) return;

      print('Remove response: ${response.statusCode} - ${response.data}'); // Debug log
      if (response.statusCode == 200) {
        _loadCart(); // Reload cart silently
      }
    } catch (e) {
      print('Remove item error: $e'); // Debug log
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Failed to remove item')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        context.pop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Shopping Cart'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_cart != null && _cart!.items.isNotEmpty)
              TextButton(
                onPressed: () => _clearCart(),
                child: const Text('Clear'),
              ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.items.isEmpty
              ? _buildEmptyCart()
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCart,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cart!.items.length,
                          itemBuilder: (context, index) {
                            final item = _cart!.items[index];
                            return _buildCartItem(item);
                          },
                        ),
                      ),
                    ),
                    _buildCartSummary(),
                  ],
                ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/categories'),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[100],
              ),
              child: item.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Icon(Icons.image),
                      errorWidget: (context, url, error) => const Icon(Icons.image),
                    )
                  : const Icon(Icons.image),
            ),
            const SizedBox(width: 16),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} ${item.unit}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(item.productId, item.qty - 0.25),
                      icon: const Icon(Icons.remove),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQuantity(item.productId, item.qty + 0.25),
                      icon: const Icon(Icons.add),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _confirmAndRemoveItem(item.productId, item.name),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal (${_cart!.itemCount} items)',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '₹${_cart!.subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/checkout'),
              child: const Text('Proceed to Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCart() async {
    try {
      final response = await DioClient().dio.delete('/cart');
      if (response.statusCode == 200) {
        _loadCart(); // Reload cart silently
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(child: Text('Failed to clear cart')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
