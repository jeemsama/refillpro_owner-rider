// lib/views/rider_screen/rider_orders.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:refillpro_owner_rider/views/rider_screen/rider_home.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model for an incoming, rider‐assigned order.
class OrderLocation {
  final int id;
  final String orderedBy;
  String status;
  final String phone;
  final bool borrow, swap;
  final String timeSlot, message;
  final int regularCount, dispenserCount;
  final double total, latitude, longitude;

  OrderLocation({
    required this.id,
    required this.orderedBy,
    required this.status,
    required this.phone,
    required this.borrow,
    required this.swap,
    required this.timeSlot,
    required this.message,
    required this.regularCount,
    required this.dispenserCount,
    required this.total,
    required this.latitude,
    required this.longitude,
  });

  factory OrderLocation.fromJson(Map<String, dynamic> j) {
    return OrderLocation(
      id: j['id'] as int,
      orderedBy: j['ordered_by'] as String,
      status: j['status'] as String,
      phone: j['phone'] as String? ?? '',
      borrow: j['borrow'] as bool,
      swap: j['swap'] as bool,
      timeSlot: j['time_slot'] as String? ?? '',
      message: j['message'] as String? ?? '',
      regularCount: j['regular_count'] as int,
      dispenserCount: j['dispenser_count'] as int,
      total: double.tryParse(j['total'].toString()) ?? 0.0,
      latitude: double.tryParse(j['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(j['longitude'].toString()) ?? 0.0,
    );
  }
}

class RiderOrders extends StatefulWidget {
  const RiderOrders({super.key});
  @override
  State<RiderOrders> createState() => _RiderOrdersState();
}

class _RiderOrdersState extends State<RiderOrders> {
  late Future<List<OrderLocation>> _futureOrders;

  @override
  void initState() {
    super.initState();
    _futureOrders = _fetchAssigned();
  }

  Future<List<OrderLocation>> _fetchAssigned() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.get(
      Uri.parse('http://192.168.1.6:8000/api/v1/rider/orders'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to load orders (${resp.statusCode})');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final all = body['data'] as List<dynamic>;

    // Only “accepted” orders
    return all
      .map((j) => OrderLocation.fromJson(j as Map<String, dynamic>))
      .where((o) => o.status == 'accepted')
      .toList();
  }

Future<void> _completeOrder(int orderId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final resp = await http.post(
    Uri.parse('http://192.168.1.6:8000/api/v1/orders/$orderId/complete'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (resp.statusCode != 200) {
    throw Exception('Failed to complete order (${resp.statusCode})');
  }
}


  Widget _buildCard(OrderLocation o) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      width: w - 32,
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: name + button/pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // left info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.orderedBy,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o.phone,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${[
                        if (o.borrow) 'Borrow',
                        if (o.swap) 'Swap'
                      ].join(' & ')} gallon',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o.timeSlot,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),

// Complete Order button / Completed pill
if (o.status == 'accepted') ...[
  ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5CB338),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    child: const Text(
      'Complete Order',
      style: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    ),
    onPressed: () async {
      try {
        await _completeOrder(o.id);
        setState(() {
          o.status = 'completed';  // ← make sure to assign, not compare
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing order: $e')),
        );
      }
    },
  ),
] else ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: ShapeDecoration(
      color: Colors.grey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50),
      ),
    ),
    child: const Text(
      'Completed',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
],

            ],
          ),

          const SizedBox(height: 12),
          if (o.message.isNotEmpty)
            Text(
              o.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w300,
              ),
            ),

          const Spacer(),

          // Footer: counts + price & location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // product counts
              Row(
                children: [
                  if (o.regularCount > 0) ...[
                    Image.asset('images/regular.png',
                        width: 35, height: 45),
                    const SizedBox(width: 4),
                    Text(
                      'x${o.regularCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (o.dispenserCount > 0) ...[
                    Image.asset('images/dispenser.png',
                        width: 30, height: 45),
                    const SizedBox(width: 4),
                    Text(
                      'x${o.dispenserCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ],
              ),

              // price & view‐location
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${o.total.toStringAsFixed(0)}.00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiderHome(
                            destination:
                                LatLng(o.latitude, o.longitude),
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Tap to view location',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w300,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title bar
        Container(
          color: const Color(0xFFF2F2F2),
          padding: const EdgeInsets.symmetric(
              vertical: 20, horizontal: 16),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Deliveries today',
              style: TextStyle(
                fontFamily: 'PoppinsExtraBold',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Accepted orders list
        Expanded(
          child: FutureBuilder<List<OrderLocation>>(
            future: _futureOrders,
            builder: (ctx, snap) {
              if (snap.connectionState !=
                  ConnectionState.done) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(
                    child: Text('Error: ${snap.error}'));
              }
              final orders = snap.data!;
              if (orders.isEmpty) {
                return const Center(
                    child: Text(
                        'No accepted deliveries yet.'));
              }
              // Remove that default top padding
return MediaQuery.removePadding(
  context: context,
  removeTop: true,
  child: RefreshIndicator(
    onRefresh: () async {
      // re-fetch and rebuild
      final fresh = await _fetchAssigned();
      setState(() {
        _futureOrders = Future.value(fresh);
      });
    },
    child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: orders.length,
      itemBuilder: (_, i) => _buildCard(orders[i]),
    ),
  ),
);
            },
          ),
        ),
      ],
    );
  }
}
