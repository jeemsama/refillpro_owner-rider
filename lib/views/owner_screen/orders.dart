// lib/views/owner_screen/orders.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:refillpro_owner_rider/views/owner_screen/maps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refillpro_owner_rider/views/model/rider.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// `OwnerOrder` model (unchanged)
/// ─────────────────────────────────────────────────────────────────────────
class OwnerOrder {
  final int id;
  final String orderedBy, phone, timeSlot, message, status;
  final int regularCount, dispenserCount;
  final bool borrow, swap;
  final double total;
  final double? latitude, longitude;
  final DateTime createdAt;
  final String? declineReason;

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
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.declineReason,
  });

  factory OwnerOrder.fromJson(Map<String, dynamic> j) {
    final raw = j['created_at'] as String;
    final createdAtUtc = raw.endsWith('Z')
        ? DateTime.parse(raw)
        : DateTime.parse('${raw}Z');

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
      createdAt: createdAtUtc,
      declineReason: j['cancel_reason_owner'] as String?,
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────
/// OrdersContent: TabBar + Order Cards + “Auto‐Cancel” + DELETE
/// ─────────────────────────────────────────────────────────────────────────
class OrdersContent extends StatefulWidget {
  final void Function(int) onNotificationCount;

  const OrdersContent({
    super.key,
    required this.onNotificationCount,
  });

  @override
  State<OrdersContent> createState() => OrdersContentState();
}

/// **Make sure this class name is public** (not `_OrdersContentState`),
/// so that a `GlobalKey<OrdersContentState>` can call `loadOrders()`.
class OrdersContentState extends State<OrdersContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  List<OwnerOrder> _orders = [];

  /// Keep a list of timers to cancel them on dispose
  final List<Timer> _cancellationTimers = [];

  @override
  void initState() {
    super.initState();

    // 4 tabs: Pending / Accepted / Completed / Declined
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(() {
        // Reload “Accepted” when its tab is shown
        if (_tabController.index == 1 && !_tabController.indexIsChanging) {
          loadOrders();
        }
      });

    // Initial load
    loadOrders();
  }

  @override
  void dispose() {
    for (final t in _cancellationTimers) {
      t.cancel();
    }
    _cancellationTimers.clear();
    _tabController.dispose();
    super.dispose();
  }

  /// ───────────────────────────────────────────────────────────────────────
  /// Public reload method that Home/Maps can call on pull‐to‐refresh.
  /// ───────────────────────────────────────────────────────────────────────
  Future<void> loadOrders() async {
    debugPrint("🔄 [Orders] loadOrders() called");
    if (!mounted) return;

    // Step 1: start loading
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getInt('owner_id');
      if (ownerId == null) throw 'No owner_id stored; please log in.';

      final uri = Uri.parse(
        'http://192.168.1.36:8000/api/v1/orders/owner?owner_id=$ownerId',
      );
      final resp = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (resp.statusCode != 200) {
        throw 'Failed to fetch orders (${resp.statusCode})';
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final listJson = body['data'] as List<dynamic>;

      // Parse into our list
      final List<OwnerOrder> fetched = listJson
          .map((e) => OwnerOrder.fromJson(e as Map<String, dynamic>))
          .toList();

      _orders = fetched;

      // Step 2: schedule auto‐cancel timers
      await _autoCancelStaleOrders(_orders);

      // ─────────────────────────────────────────────────────────
      // Step 3: compute the “pending” count and fire callback
      final int pendingCount = _orders
          .where((o) => o.status.toLowerCase() == 'pending')
          .length;
      
      debugPrint("🔔 [Orders] pendingCount = $pendingCount → calling onNotificationCount");

      // Wrap the callback in setState to guarantee ordering
      setState(() {
        widget.onNotificationCount(pendingCount);
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  /// ───────────────────────────────────────────────────────────────────────
  /// Auto‐cancel stale “pending” orders after 2 hours
  /// ───────────────────────────────────────────────────────────────────────
  Future<void> _autoCancelStaleOrders(List<OwnerOrder> orders) async {
    // Cancel any old timers
    for (final t in _cancellationTimers) {
      t.cancel();
    }
    _cancellationTimers.clear();

    final nowUtc = DateTime.now().toUtc();
    final twoHours = const Duration(hours: 2);
    final List<int> immediateCancelIds = [];

    for (final o in orders) {
      if (o.status.toLowerCase() != 'pending') continue;
      final createdUtc =
          o.createdAt.isUtc ? o.createdAt : o.createdAt.toUtc();
      final diff = nowUtc.difference(createdUtc);

      if (diff >= twoHours) {
        immediateCancelIds.add(o.id);
        continue;
      }

      final expireAtUtc =
          createdUtc.add(twoHours).add(const Duration(seconds: 1));
      final remaining = expireAtUtc.difference(nowUtc);
      if (remaining.inMilliseconds > 0) {
        final timer = Timer(remaining, () async {
          if (!mounted) return;
          await _declineOrder(o.id, 'auto_cancel');
        });
        _cancellationTimers.add(timer);
      }
    }

    if (immediateCancelIds.isNotEmpty) {
      for (final id in immediateCancelIds) {
        try {
          await _declineOrder(id, 'auto_cancel');
        } catch (_) {}
      }
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await loadOrders();
    }
  }

  /// ───────────────────────────────────────────────────────────────────────
  /// Fetch the list of available riders
  /// ───────────────────────────────────────────────────────────────────────
  Future<List<Rider>> _fetchRiders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.get(
      Uri.parse('http://192.168.1.36:8000/api/v1/riders'),
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
      Uri.parse('http://192.168.1.36:8000/api/v1/orders/$orderId/accept'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'assigned_rider_id': riderId}),
    );
    if (resp.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign: ${resp.statusCode}')),
      );
    } else {
      // After assigning, reload to update pending count & UI
      await loadOrders();
    }
  }

  Future<void> _declineOrder(int orderId, String reason) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.post(
      Uri.parse('http://192.168.1.36:8000/api/v1/orders/$orderId/decline'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'reason': reason}),
    );
    if (resp.statusCode != 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: ${resp.statusCode}')),
      );
    } else {
      // After declining, reload to update UI & pending count
      await loadOrders();
    }
  }

  Future<void> _deleteOrder(int orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final resp = await http.delete(
      Uri.parse('http://192.168.1.36:8000/api/v1/orders/$orderId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 204) {
      await loadOrders();
    } else {
      throw 'Delete failed (${resp.statusCode})';
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
      'Too far to deliver',
      'Delivery service not available',
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
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
                      Text(
                        o.orderedBy,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        o.phone,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${[if (o.borrow) 'Borrow', if (o.swap) 'Swap'].join(' & ')} gallon',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 2),
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

                // actions (status + buttons)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      o.status.capitalize(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    if (o.status.toLowerCase() == 'pending') ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _showPassToRiderDialog(o.id),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5CB338),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _showDeclineDialog(o.id);
                            },
                            child: Container(
                              width: 40,
                              height: 40,
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

                    if (o.status.toLowerCase() == 'accepted') ...[
                      const SizedBox(height: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        tooltip: 'Remove order',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Confirm delete'),
                              content:
                                  const Text('Permanently delete this order?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await _deleteOrder(o.id);
                            } catch (e) {
                              if (!mounted) return;
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (o.regularCount > 0) ...[
                      Image.asset('assets/images/regular.png',
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
                      Image.asset('assets/images/dispenser.png',
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
                    ]
                  ],
                ),

                if (o.status.toLowerCase() != 'declined') ...[
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
                  )
                ] else ...[
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Remove this declined order',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete declined order?'),
                          content: const Text(
                              'This will permanently remove the declined order.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        try {
                          await _deleteOrder(o.id);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete: $e')),
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
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
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
                  child: Row(
                    children: [
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
                        labelStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        unselectedLabelStyle: const TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w500),
                        indicatorSize: TabBarIndicatorSize.label,
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'Accepted'),
                          Tab(text: 'Completed'),
                          Tab(text: 'Declined'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // ─ Pending ───────────────────────────────────────────
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_error != null)
                Center(child: Text('Error: $_error'))
              else
                SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFFDCDC),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.black54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Customer order will auto cancel if you don’t make any actions within 2 hours.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      if (_orders
                          .where((o) => o.status.toLowerCase() == 'pending')
                          .isEmpty)
                        const Center(child: Text('No pending orders'))
                      else
                        Column(
                          children: _orders
                              .where((o) =>
                                  o.status.toLowerCase() == 'pending')
                              .map(_buildOrderCard)
                              .toList(),
                        ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),

              // ─ Accepted ──────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: _orders
                      .where((o) => o.status.toLowerCase() == 'accepted')
                      .map(_buildOrderCard)
                      .toList(),
                ),
              ),

              // ─ Completed ─────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: _orders
                      .where((o) => o.status.toLowerCase() == 'completed')
                      .map(_buildOrderCard)
                      .toList(),
                ),
              ),

              // ─ Declined ──────────────────────────────────────────
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final declinedIds = _orders
                                .where((o) =>
                                    o.status.toLowerCase() == 'declined')
                                .map((o) => o.id)
                                .toList();
                            if (declinedIds.isEmpty) return;

                            final confirmAll = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title:
                                    const Text('Delete ALL declined orders?'),
                                content: const Text(
                                    'This will remove every declined order permanently.'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, true),
                                      child: const Text('Delete All')),
                                ],
                              ),
                            );
                            if (confirmAll != true) return;

                            for (final id in declinedIds) {
                              try {
                                await _deleteOrder(id);
                              } catch (_) {
                                // ignore failures
                              }
                            }
                          },
                          icon: const Icon(Icons.delete_forever,
                              size: 20, color: Color(0xffA62C2C)),
                          label: const Text(
                            'Delete All',
                            style: TextStyle(color: Color(0xffA62C2C)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFFFFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    ..._orders
                        .where((o) => o.status.toLowerCase() == 'declined')
                        .map(_buildOrderCard),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper: Capitalize string
extension StringCap on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}
