import 'package:flutter/material.dart';
import '../state/partner_app_state.dart';
import 'orders_screen.dart';

class OrdersTab extends StatelessWidget {
  const OrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OrdersScreen(
        vendorId: partnerAppState.vendorId ?? '0',
      ),
    );
  }
}
