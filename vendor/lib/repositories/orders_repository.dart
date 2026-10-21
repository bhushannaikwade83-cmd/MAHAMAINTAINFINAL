import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/kyc_backend_config.dart';
import '../widgets/debug_console.dart';
import 'auth_repository.dart';

class Order {
  final int id;
  final String orderId;
  final String? cartId;
  final String? userId;
  final String? pincode;
  final bool pincodeMatches;
  final List<String> vendorPincodes;
  final double totalAmount;
  final double discountAmount;
  final String? couponCode;
  final int serviceCount;
  final String? scheduledAt;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;
  final String createdAt;

  Order({
    required this.id,
    required this.orderId,
    this.cartId,
    this.userId,
    this.pincode,
    this.pincodeMatches = false,
    this.vendorPincodes = const [],
    required this.totalAmount,
    required this.discountAmount,
    this.couponCode,
    required this.serviceCount,
    this.scheduledAt,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? '',
      cartId: json['cart_id'],
      userId: json['user_id'],
      pincode: json['pincode'],
      pincodeMatches: json['pincode_matches'] ?? false,
      vendorPincodes: List<String>.from((json['vendor_pincodes'] as List?)?.map((p) => p.toString()) ?? []),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['coupon_code'],
      serviceCount: json['service_count'] ?? 0,
      scheduledAt: json['scheduled_at'],
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'],
      orderStatus: json['order_status'],
      createdAt: json['created_at'] ?? '',
    );
  }
}

class OrdersRepository {
  Future<List<Order>> fetchOrders(String vendorId) async {
    final console = DebugConsole();
    console.log('Fetching orders for vendor: $vendorId');
    console.log('URL: ${KycBackendConfig.backendBaseUrl}/get-vendor-orders.php');

    try {
      final response = await http.get(
        Uri.parse('${KycBackendConfig.backendBaseUrl}/get-vendor-orders.php'),
        headers: SupabaseAuthRepository.staticAuthHeaders,
      );

      console.log('Response status: ${response.statusCode}');
      console.log('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final orders = ((data['orders'] as List?) ?? [])
              .map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList();
          console.log('Loaded ${orders.length} orders');
          return orders;
        } else {
          console.error('Failed to load orders', data['error']);
          throw Exception(data['error'] ?? 'Failed to load orders');
        }
      } else {
        console.error('Failed to load orders: ${response.statusCode}');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      console.error('Exception while fetching orders', e);
      rethrow;
    }
  }
}
