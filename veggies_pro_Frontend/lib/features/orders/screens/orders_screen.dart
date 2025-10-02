import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/dio_client.dart';
import '../../../models/address.dart';

class Order {
  final String id;
  final List<OrderItem> items;
  final Address address;
  final TimeSlot timeSlot;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final Payment payment;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.items,
    required this.address,
    required this.timeSlot,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.payment,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      address: Address.fromJson(json['address'] as Map<String, dynamic>? ?? {}),
      timeSlot: TimeSlot.fromJson(json['timeSlot'] as Map<String, dynamic>? ?? {}),
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      deliveryFee: (json['deliveryFee'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      payment: Payment.fromJson(json['payment'] as Map<String, dynamic>? ?? {}),
      status: json['status']?.toString() ?? 'placed',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }
}

class OrderItem {
  final String productId;
  final String name;
  final String image;
  final String unit;
  final double qty;
  final double unitPrice;
  final double price;

  OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.unit,
    required this.qty,
    required this.unitPrice,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      unit: json['unit']?.toString() ?? '',
      qty: (json['qty'] ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

class TimeSlot {
  final String date;
  final String startTime;
  final String endTime;

  TimeSlot({
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      date: json['date']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
    );
  }

  String get display {
    final dateTime = DateTime.parse(date);
    final dayName = _getDayName(dateTime.weekday);
    return '$dayName, ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String get timeRange => '$startTime - $endTime';

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

class Payment {
  final String provider;
  final String status;
  final String? orderId;
  final String? paymentId;
  final String? signature;

  Payment({
    required this.provider,
    required this.status,
    this.orderId,
    this.paymentId,
    this.signature,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      provider: json['provider']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      paymentId: json['paymentId']?.toString(),
      signature: json['signature']?.toString(),
    );
  }

  String get displayName {
    switch (provider) {
      case 'razorpay':
        return 'Card/UPI Payment';
      case 'cod':
        return 'Cash on Delivery';
      default:
        return provider.toUpperCase();
    }
  }
}

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await DioClient().dio.get('/orders');
      if (response.statusCode == 200) {
        final responseData = response.data;
        print('Orders API Response: $responseData'); // Debug log
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final ordersData = responseData['data'];
          if (ordersData is List) {
            setState(() {
              _orders = ordersData
                  .map((order) => Order.fromJson(order as Map<String, dynamic>))
                  .toList();
            });
          } else {
            print('Orders data is not a list: $ordersData');
            setState(() {
              _orders = [];
            });
          }
        } else {
          print('Orders API returned unsuccessful response or null data');
          setState(() {
            _orders = [];
          });
        }
      }
    } catch (e) {
      print('Orders loading error: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _orders = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'placed':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.blue;
      case 'confirmed':
        return Colors.orange;
      case 'preparing':
        return Colors.purple;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
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
          title: const Text('My Orders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No orders yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
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

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(order.status),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusText(order.status),
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on ${_formatDate(order.createdAt)}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            
            // Order items
            ...order.items.take(2).map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.name} (${item.qty.toStringAsFixed(item.qty % 1 == 0 ? 0 : 2)} ${item.unit})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Text(
                    '₹${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            
            if (order.items.length > 2) ...[
              Text(
                '+${order.items.length - 2} more items',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            const Divider(),
            
            // Delivery info
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${order.address.city}, ${order.address.state}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${order.timeSlot.display} • ${order.timeSlot.timeRange}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.payment,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  order.payment.displayName,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}