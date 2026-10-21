import 'package:flutter/material.dart';
import '../repositories/orders_repository.dart';
import '../widgets/debug_console.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  final String vendorId;

  const OrdersScreen({
    Key? key,
    required this.vendorId,
  }) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late OrdersRepository _ordersRepository;
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ordersRepository = OrdersRepository();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final console = DebugConsole();
    console.log('Loading orders for vendor: ${widget.vendorId}');

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _ordersRepository.fetchOrders(widget.vendorId);
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
      console.log('Loaded ${orders.length} orders');
    } catch (e) {
      console.error('Error loading orders', e);
      setState(() {
        _error = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
        return '✓ Completed';
      case 'CONFIRMED':
        return '✓ Confirmed';
      case 'PENDING':
        return '⏳ Pending';
      case 'CANCELLED':
        return '✗ Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _getStatusBgColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'CONFIRMED':
        return Colors.green.shade100;
      case 'CANCELLED':
        return Colors.red.shade100;
      case 'PENDING':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status?.toUpperCase()) {
      case 'COMPLETED':
      case 'CONFIRMED':
        return Colors.green.shade700;
      case 'CANCELLED':
        return Colors.red.shade700;
      case 'PENDING':
        return Colors.orange.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadOrders,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No orders yet\nOrders from customers will appear here',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final createdDate = DateTime.parse(order.createdAt);
                        final formattedDate =
                            DateFormat('dd MMM yyyy, hh:mm a').format(createdDate);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order ID and Status
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order.orderId}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFF97316),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusBgColor(order.orderStatus),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _getStatusColor(order.orderStatus),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _getStatusTextColor(order.orderStatus),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Order Details
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${order.serviceCount} Service${order.serviceCount != 1 ? 's' : ''}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        if (order.pincode != null && order.pincode!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 6),
                                            child: Row(
                                              children: [
                                                Text(
                                                  '📍 ${order.pincode}',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: order.pincodeMatches ? Colors.green.shade700 : Colors.orange.shade700,
                                                  ),
                                                ),
                                                if (order.pincodeMatches)
                                                  const Padding(
                                                    padding: EdgeInsets.only(left: 6),
                                                    child: Text(
                                                      '✓ Your Area',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  )
                                                else if (order.vendorPincodes.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 6),
                                                    child: Text(
                                                      '⚠ Outside Service',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.orange.shade700,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '₹${order.totalAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFF97316),
                                      ),
                                    ),
                                  ],
                                ),

                                if (order.discountAmount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Discount: -₹${order.discountAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),

                                if (order.paymentStatus != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Payment: ${order.paymentStatus}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
