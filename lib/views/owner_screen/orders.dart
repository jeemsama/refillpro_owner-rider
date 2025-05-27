// lib/views/owner_screen/orders.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refillpro_owner_rider/views/model/rider.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'maps.dart';
import 'home.dart';
import 'profile.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});
  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  int _selectedIndex = 2;
  static const _screens = <Widget>[
    HomeContent(),
    MapsContent(),
    OrdersContent(),
    ProfileContent(),
  ];

  void _onItemTapped(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    final showHeader = _selectedIndex != 3;
    final showNav = _selectedIndex != 3;

    return Scaffold(
      backgroundColor: const Color(0xffF1EFEC),
      body: Stack(children: [
        if (showHeader)
          const Positioned(top: 50, left: 0, right: 0, child: AppHeader()),
        Positioned(
          top: showHeader ? 83 : 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: !showHeader,
            child: Stack(children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: showNav ? 70 : 0,
                child: _screens[_selectedIndex],
              ),
              if (showNav)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: CustomBottomNavBar(
                    selectedIndex: 2,
                    onItemTapped: _onItemTapped,
                  ),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Data model for an incoming order
class OwnerOrder {
  final int id;
  final String orderedBy, phone, timeSlot, message, status;
  final int regularCount, dispenserCount;
  final bool borrow, swap;
  final double total;
  final double? latitude, longitude;

  OwnerOrder({
    required this.id,
    required this.orderedBy,
    required this.phone,
    required this.timeSlot,
    required this.message,
    required this.status,
    required this.regularCount,
    required this.dispenserCount,
    required this.borrow,
    required this.swap,
    required this.total,
    this.latitude,
    this.longitude,
  });

  factory OwnerOrder.fromJson(Map<String, dynamic> j) {
    return OwnerOrder(
      id: j['id'] as int,
      orderedBy: j['ordered_by'] as String,
      phone: j['phone'] as String,
      timeSlot: j['time_slot'] as String,
      message: j['message'] as String? ?? '',
      status: j['status'] as String,
      regularCount: j['regular_count'] as int,
      dispenserCount: j['dispenser_count'] as int,
      borrow: j['borrow'] as bool,
      swap: j['swap'] as bool,
      total: double.parse(j['total'].toString()),
      latitude: j['latitude'] != null
          ? double.tryParse(j['latitude'].toString())
          : null,
      longitude: j['longitude'] != null
          ? double.tryParse(j['longitude'].toString())
          : null,
    );
  }
}

/// The Orders tab: fetch + show Pending / Accepted / Cancelled
class OrdersContent extends StatefulWidget {
  const OrdersContent({super.key});
  @override
  State<OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<OrdersContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  List<OwnerOrder> _orders = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController.index == 1 && !_tabController.indexIsChanging) {
          // user just switched to "Accepted"
          _loadOrders();
        }
      });

    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getInt('owner_id');
      if (ownerId == null) throw 'No owner_id stored; please log in.';

      final uri = Uri.parse(
          'http://192.168.1.6:8000/api/v1/orders/owner?owner_id=$ownerId');
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      if (resp.statusCode != 200) {
        throw 'Failed to fetch orders (${resp.statusCode})';
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>);
      _orders = list
          .map((e) => OwnerOrder.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<List<Rider>> _fetchRiders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.get(
      Uri.parse('http://192.168.1.6:8000/api/v1/riders'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode != 200) {
      throw 'Could not load riders (${resp.statusCode})';
    }
    final data = json.decode(resp.body) as List;
    return data.map((j) => Rider.fromJson(j)).toList();
  }

  Future<void> _assignOrderToRider(int orderId, int riderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.post(
      Uri.parse('http://192.168.1.6:8000/api/v1/orders/$orderId/accept'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      // use rider_id here
      body: json.encode({'assigned_rider_id': riderId}),
    );
    if (resp.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign: ${resp.statusCode}')),
      );
    } else {
      await _loadOrders();  // refresh your owner list so you see it move to “Accepted”
    }
  }


  // DELETE /api/v1/orders/{id}
Future<void> _deleteOrder(int orderId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final resp = await http.delete(
    Uri.parse('http://192.168.1.6:8000/api/v1/orders/$orderId'),
    headers: {
      'Accept':        'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  if (resp.statusCode == 204) {
    // removed on server → reload locally
    await _loadOrders();
  } else {
    throw 'Delete failed (${resp.statusCode})';
  }
}




  // 1) Add this helper alongside _assignOrder():
  Future<void> _declineOrder(int orderId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.post(
      Uri.parse('http://192.168.1.6:8000/api/v1/orders/$orderId/decline'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );
    if (resp.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: ${resp.statusCode}')),
      );
    } else {
      await _loadOrders();
    }
  }


  void _showPassToRiderDialog(int orderId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF455567),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: FutureBuilder<List<Rider>>(
          future: _fetchRiders(),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snap.hasError || (snap.data?.isEmpty ?? true)) {
              return SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    snap.error?.toString() ?? 'No riders found',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }

            Rider? selected;
            return StatefulBuilder(builder: (ctx2, setSt) {
              return Container(
                width: 215,
                height: 180,
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: const Color(0xFF455567),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Accept order?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<Rider>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text(
                          'Pass to the rider',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: selected,
                        items: snap.data!
                            .map((r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      )),
                                ))
                            .toList(),
                        onChanged: (r) => setSt(() => selected = r),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: selected == null
                          ? null
                          : () async {
                              Navigator.of(ctx).pop();
                              await _assignOrderToRider(orderId, selected!.id);
                              await _loadOrders();
                            },
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            });
          },
        ),
      ),
    );
  }

  void _showDeclineDialog(int orderId) {
    final reasons = [
      'Out of stock',
      'Invalid location',
      'Customer unreachable',
      'Other',
    ];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF455567),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: StatefulBuilder(builder: (ctx2, setSt) {
          return Container(
            width: 215,
            height: 180,
            padding: const EdgeInsets.all(16),
            decoration: ShapeDecoration(
              color: const Color(0xFF455567),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Decline order?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Reason for declining?',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: selectedReason,
                    items: reasons
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500)),
                            ))
                        .toList(),
                    onChanged: (v) => setSt(() => selectedReason = v),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: selectedReason == null
                      ? null
                      : () {
                          Navigator.of(ctx).pop();
                          _declineOrder(orderId, selectedReason!);
                        },
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOrderCard(OwnerOrder o) {
    final mq = MediaQuery.of(context);
    final screenWidth = mq.size.width;
    const cardHeight = 200.0;
    return Container(
      width: screenWidth - 32,
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // left info
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.orderedBy,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(o.phone,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300)),
                      const SizedBox(height: 2),
                      Text(
                          '${[if (o.borrow) 'Borrow', if (o.swap) 'Swap'].join(' & ')} gallon',
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300)),
                      const SizedBox(height: 2),
                      Text(o.timeSlot,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300)),
                    ],
                  ),
                ),

                // actions
Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(o.status.capitalize(),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
    ),

    // PENDING: accept/decline buttons (unchanged)
    if (o.status == 'pending') ...[
      const SizedBox(height: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showPassToRiderDialog(o.id),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF5CB338),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              _showDeclineDialog(o.id);
              await _loadOrders();
            },
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFA62C2C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    ],

    // ACCEPTED: show trash icon to delete
    if (o.status == 'accepted') ...[
      const SizedBox(height: 8),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.redAccent),
        tooltip: 'Remove order',
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Confirm delete'),
              content: const Text('Permanently delete this order?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            try {
              await _deleteOrder(o.id);
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting: $e')),
              );
            }
          }
        },
      ),
    ],
  ],
),

              ],
            ),

            const SizedBox(height: 12),
            if (o.message.isNotEmpty)
              Text(o.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w300)),
            const Spacer(),

            // footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // counts
                Row(
                  children: [
                    if (o.regularCount > 0) ...[
                      Image.asset('images/regular.png',
                          width: 35, height: 45),
                      const SizedBox(width: 4),
                      Text('x${o.regularCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300)),
                      const SizedBox(width: 16),
                    ],
                    if (o.dispenserCount > 0) ...[
                      Image.asset('images/dispenser.png',
                          width: 30, height: 45),
                      const SizedBox(width: 4),
                      Text('x${o.dispenserCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300)),
                    ]
                  ],
                ),

                // total & location
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₱${o.total.toStringAsFixed(0)}.00',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () {
                        if (o.latitude != null && o.longitude != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Maps(
                                destination:
                                    LatLng(o.latitude!, o.longitude!),
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Tap to view location',
                          style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w300,
                              decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Column(children: [
      // Title + TabBar
      PreferredSize(
        preferredSize: const Size.fromHeight(77),
        child: Container(
          color: const Color(0xFFF1EFEC),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(children: [
                  const Text(
                    'Orders',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'PoppinsExtraBold',
                    ),
                  ),
                  const Spacer(),
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.black,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Accepted'),
                      Tab(text: 'Declined'),
                    ],
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),

      // Tab views
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Pending
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(child: Text('Error: $_error'))
            else if (_orders.where((o) => o.status == 'pending').isEmpty)
              const Center(child: Text('No pending orders'))
            else
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: _orders
                      .where((o) => o.status == 'pending')
                      .map(_buildOrderCard)
                      .toList(),
                ),
              ),

            // Accepted
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: _orders
                  .where((o) => o.status=='accepted')
                  .map(_buildOrderCard)
                  .toList(),
              ),
            ),

            // Cancelled
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: _orders
                  .where((o) => o.status=='declined')
                  .map(_buildOrderCard)
                  .toList(),
              ),
            ),
          ],
        ),
      ),
    ]);
  }
}




/// Capitalize helper
extension StringCap on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
