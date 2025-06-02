// lib/views/owner_screen/maps.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_map/flutter_map.dart';         // ← for PolylineLayer
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/owner_screen/orders.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';

class Maps extends StatefulWidget {
  /// If you push this screen, pass in the tapped order coords:
  /// Navigator.push(context, MaterialPageRoute(
  ///   builder: (_) => Maps(destination: LatLng(lat, lng)),
  /// ));
  final LatLng? destination;
  const Maps({super.key, this.destination});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  int _selectedIndex = 1;

  late final List<Widget> _screens = [
    HomeContent(),
    MapsContent(destination: widget.destination),
    OrdersContent(),
    ProfileContent(),
  ];

  void _onItemTapped(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1EFEC),
      body: Stack(children: [
        const Positioned(top: 50, left: 0, right: 0, child: AppHeader()),
        Positioned(
          top: 83,
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Stack(children: [
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                bottom: 97,
                child: _screens[_selectedIndex],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 30,
                child: CustomBottomNavBar(
                  selectedIndex: _selectedIndex,
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

/// Your shop model
class ShopDetail {
  final int id, ownerId;
  final String shopName;
  final double lat, lng;

  ShopDetail({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.lat,
    required this.lng,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> j) => ShopDetail(
        id: j['id'] as int,
        ownerId: j['owner_id'] as int,
        shopName: j['shop_name'] as String,
        lat: double.parse(j['latitude'].toString()),
        lng: double.parse(j['longitude'].toString()),
      );
}

/// Incoming order with coords
class OrderLocation {
  final int id;
  final String orderedBy, status;
  final double lat, lng;

  OrderLocation({
    required this.id,
    required this.orderedBy,
    required this.status,
    required this.lat,
    required this.lng,
  });

  factory OrderLocation.fromJson(Map<String, dynamic> j) => OrderLocation(
        id: j['id'] as int,
        orderedBy: j['ordered_by'] as String,
        status: j['status'] as String,
        lat: double.parse(j['latitude'].toString()),
        lng: double.parse(j['longitude'].toString()),
      );
}

class MapsContent extends StatefulWidget {
  final LatLng? destination;
  const MapsContent({super.key, this.destination});

  @override
  State<MapsContent> createState() => _MapsContentState();
}

class _MapsContentState extends State<MapsContent> {
  final MapController _mapController = MapController();
  ShopDetail? _mine;
  List<OrderLocation> _orders = [];
  List<LatLng> _routePoints = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll().then((_) {
      if (widget.destination != null && _mine != null) {
        _getRouteFromApi(
          LatLng(_mine!.lat, _mine!.lng),
          widget.destination!,
        );
      }
    });
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final myOwnerId = prefs.getInt('owner_id');
      if (myOwnerId == null) {
        throw 'No owner_id saved – please log in first.';
      }

      // 1️⃣ load your station
      final stationRes = await http.get(
        Uri.parse('http://192.168.1.17:8000/api/v1/refill-stations'),
        headers: {'Accept': 'application/json'},
      );
      if (stationRes.statusCode != 200) {
        throw 'Stations failed (${stationRes.statusCode})';
      }
      final stations = (jsonDecode(stationRes.body) as List)
          .map((e) => ShopDetail.fromJson(e))
          .where((s) => s.ownerId == myOwnerId)
          .toList();
      if (stations.isEmpty) {
        throw 'No approved station for owner=$myOwnerId';
      }
      _mine = stations.first;

      // 2️⃣ load your orders
      final ordersRes = await http.get(
        Uri.parse(
            'http://192.168.1.17:8000/api/v1/orders/owner?owner_id=$myOwnerId'),
        headers: {'Accept': 'application/json'},
      );
      if (ordersRes.statusCode != 200) {
        throw 'Orders failed (${ordersRes.statusCode})';
      }
      final data = jsonDecode(ordersRes.body)['data'] as List;
_orders = data
  .where((j) => j['status'] == 'pending' && j['latitude'] != null && j['longitude'] != null)
  .map((j) => OrderLocation.fromJson(j as Map<String, dynamic>))
  .toList();

      // center on your shop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(_mine!.lat, _mine!.lng),
          14.0,
        );
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _getRouteFromApi(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car'
      '?api_key=5b3ce3597851110001cf6248a6164b7235ef4e3f860b56fb548d5a35'
      '&start=${start.longitude},${start.latitude}'
      '&end=${end.longitude},${end.latitude}',
    );

    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final coords = (json.decode(resp.body)['features'][0]['geometry']
                ['coordinates'] as List)
            .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        if (mounted) {
          setState(() => _routePoints = coords);
          if (coords.isNotEmpty) _mapController.move(coords.first, 15);
        }
      } else {
        throw 'Route failed: ${resp.statusCode}';
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Route error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text('Error: $_error', textAlign: TextAlign.center),
      );
    }
    if (_mine == null) return const Center(child: Text('No station data'));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_mine!.lat, _mine!.lng),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),

        // ▶︎ draw the route
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _routePoints, strokeWidth: 12, color: Color(0xFF455567)),
            ],
          ),

        // ▶︎ shop marker
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_mine!.lat, _mine!.lng),
              width: 50,
              height: 50,
              child: Image.asset('images/store_tag1.png'),
            ),
          ],
        ),

        // ▶︎ order markers
        MarkerLayer(
          markers: _orders.map((o) => Marker(
                point: LatLng(o.lat, o.lng),
                width: 50,
                height: 50,
                child: Image.asset('images/customer_tag1.png'),
              )).toList(),
        ),
      ],
    );
  }
}
