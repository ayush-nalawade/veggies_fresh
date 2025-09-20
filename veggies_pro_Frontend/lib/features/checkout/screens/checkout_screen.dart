import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../core/dio_client.dart';
import '../../../core/env.dart';
import '../../../models/cart.dart';
import '../../../models/address.dart';
import '../../../services/profile_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  Cart? _cart;
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load cart and addresses in parallel
      final results = await Future.wait([
        _loadCart(),
        _loadAddresses(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCart() async {
    try {
      final response = await DioClient().dio.get('/cart');
      if (response.statusCode == 200) {
        setState(() {
          _cart = Cart.fromJson(response.data['data']);
        });
      }
    } catch (e) {
      throw Exception('Failed to load cart: $e');
    }
  }

  Future<void> _loadAddresses() async {
    try {
      final addresses = await ProfileService().getAddresses();
      setState(() {
        _addresses = addresses;
        // Auto-select default address if available
        if (addresses.isNotEmpty) {
          _selectedAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.first,
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to load addresses: $e');
    }
  }

  Future<void> _proceedToPayment() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      // Create order with selected address
      final orderResponse = await DioClient().dio.post('/checkout/create-order', data: {
        'address': {
          'line1': _selectedAddress!.line1,
          'line2': _selectedAddress!.line2,
          'city': _selectedAddress!.city,
          'state': _selectedAddress!.state,
          'pincode': _selectedAddress!.pincode,
          'country': _selectedAddress!.country,
        }
      });

      if (orderResponse.statusCode == 200) {
        final orderData = orderResponse.data['data'];
        _openRazorpayCheckout(orderData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  void _openRazorpayCheckout(Map<String, dynamic> orderData) {
    var options = {
      'key': Env.razorpayKeyId,
      'amount': orderData['amount'],
      'currency': 'INR',
      'name': 'VeggieFresh',
      'order_id': orderData['razorpayOrderId'],
      'prefill': {
        'email': 'user@example.com', // You can get this from user data
        'contact': '', // Phone will be filled from selected address if needed
      },
      'theme': {
        'color': '#2E7D32'
      }
    };

    _razorpay.open(options);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final verifyResponse = await DioClient().dio.post('/checkout/verify-payment', data: {
        'razorpayOrderId': response.orderId,
        'paymentId': response.paymentId,
        'signature': response.signature,
        'orderId': response.orderId, // You might need to store this from create-order
      });

      if (verifyResponse.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Order placed.'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/orders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment verification failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External wallet selected: ${response.walletName}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cart == null || _cart!.items.isEmpty
              ? _buildEmptyCart()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAddressSection(),
                      const SizedBox(height: 24),
                      _buildOrderSummary(),
                      const SizedBox(height: 24),
                      _buildPaymentButton(),
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
            onPressed: () => context.go('/categories'),
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Address',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await context.push<bool>('/profile/addresses/add');
                if (result == true) {
                  _loadAddresses();
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        if (_addresses.isEmpty)
          _buildNoAddressCard()
        else
          _buildAddressList(),
      ],
    );
  }

  Widget _buildNoAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No addresses found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a delivery address to continue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await context.push<bool>('/profile/addresses/add');
                if (result == true) {
                  _loadAddresses();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Address'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return Column(
      children: _addresses.map((address) => _buildAddressCard(address)).toList(),
    );
  }

  Widget _buildAddressCard(Address address) {
    final isSelected = _selectedAddress?.id == address.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedAddress = address;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          child: Row(
            children: [
              Radio<Address>(
                value: address,
                groupValue: _selectedAddress,
                onChanged: (value) {
                  setState(() {
                    _selectedAddress = value;
                  });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getAddressIcon(address.type),
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          address.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'DEFAULT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address.fullAddress,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final result = await context.push<bool>(
                    '/profile/addresses/edit',
                    extra: address,
                  );
                  if (result == true) {
                    _loadAddresses();
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String type) {
    switch (type) {
      case 'home':
        return Icons.home;
      case 'work':
        return Icons.work;
      default:
        return Icons.location_on;
    }
  }

  Widget _buildOrderSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Summary',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ..._cart!.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} (${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} ${item.unit})',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
                const Divider(),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Fee',
                      style: TextStyle(fontSize: 16),
                    ),
                    const Text(
                      '₹0',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${_cart!.subtotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessingPayment ? null : _proceedToPayment,
        child: _isProcessingPayment
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Proceed to Payment'),
      ),
    );
  }
}
