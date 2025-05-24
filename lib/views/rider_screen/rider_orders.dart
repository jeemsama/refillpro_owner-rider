import 'package:flutter/material.dart';

class RiderOrders extends StatelessWidget {
  const RiderOrders({super.key});

  @override
  Widget build(BuildContext context) {
    // just your orders UI — no Scaffold here!
    return Center(
      child: Text(
        'Your Orders',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}
