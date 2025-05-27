// lib/views/rider_screen/rider_home.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:refillpro_owner_rider/views/rider_screen/rider_profile.dart';
import 'package:refillpro_owner_rider/views/custom_bottom_navbar_rider.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/rider_screen/rider_orders.dart'
    show OrderLocation, RiderOrders;

class Station {
  final int id;
  final String shopName;
  final double lat, lng;
  Station({
    required this.id,
    required this.shopName,
    required this.lat,
    required this.lng,
  });
  factory Station.fromJson(Map<String, dynamic> j) => Station(
    id: j['id'] as int,
    shopName: j['shop_name'] as String,
    lat: double.parse(j['latitude'].toString()),
    lng: double.parse(j['longitude'].toString()),
  );
}

class RiderHome extends StatefulWidget {
  /// If you push this screen with a tapped order:
  /// Navigator.push(..., builder: (_) => RiderHome(destination: LatLng(lat, lng)));
  final LatLng? destination;
  const RiderHome({super.key, this.destination});

  @override
  // ignore: library_private_types_in_public_api
  _RiderHomeState createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  final MapController _mapCtl = MapController();

  late Future<Station?> _stationFuture;
  late Future<List<OrderLocation>> _ordersFuture;
  List<LatLng> _routePoints = [];

  int _selectedIndex = 0;
  static const _orsApiKey =
      '5b3ce3597851110001cf6248a6164b7235ef4e3f860b56fb548d5a35';

  @override
  void initState() {
    super.initState();

    // 1️⃣ Kick off loading station + orders
    _stationFuture = _loadStation();
    _ordersFuture = _fetchAssignedOrders();

    // 2️⃣ If somebody tapped "view location", draw that route
    if (widget.destination != null) {
      _stationFuture.then((station) {
        if (station != null) {
          _getRouteFromApi(
            LatLng(station.lat, station.lng),
            widget.destination!,
          );
        }
      });
    }
  }

  Future<Station?> _loadStation() async {
    final prefs = await SharedPreferences.getInstance();
    final ownerId = prefs.getInt('owner_id');
    if (ownerId == null) return null;

    final resp = await http.get(
      Uri.parse('http://192.168.1.6:8000/api/v1/refill-stations'),
      headers: {'Accept': 'application/json'},
    );
    if (resp.statusCode != 200) return null;

    final list = jsonDecode(resp.body) as List<dynamic>;
    final match = list.firstWhere(
      (e) => e['owner_id'] == ownerId,
      orElse: () => null,
    );
    return match == null
        ? null
        : Station.fromJson(match as Map<String, dynamic>);
  }

  Future<List<OrderLocation>> _fetchAssignedOrders() async {
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
      throw Exception('Could not load assignments (${resp.statusCode})');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>;
    return data
        .map((j) => OrderLocation.fromJson(j as Map<String, dynamic>))
        .where((o) => o.status == 'accepted')
        .toList();
  }

  Future<void> _getRouteFromApi(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car'
      '?api_key=$_orsApiKey'
      '&start=${start.longitude},${start.latitude}'
      '&end=${end.longitude},${end.latitude}',
    );
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final coords = (json.decode(resp.body)['features'][0]['geometry']
              ['coordinates'] as List)
          .map<LatLng>((c) => LatLng(c[1] as double, c[0] as double))
          .toList();
      if (mounted) {
        setState(() => _routePoints = coords);
        if (coords.isNotEmpty) _mapCtl.move(coords.first, 15.0);
      }
    }
    // otherwise fail silently
  }

  void _onItemTapped(int idx) {
    setState(() => _selectedIndex = idx);
    // whenever we come back to map tab, re-center on station
    if (idx == 0) {
      _stationFuture.then((st) {
        if (st != null) _mapCtl.move(LatLng(st.lat, st.lng), 13.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHeader = _selectedIndex != 2;
    final showNav = _selectedIndex != 2;

    final tabs = <Widget>[
      // ─── MAP TAB ───────────────────────────
      // ─── MAP TAB w/ pull-to-refresh ───────────────────────────
      FutureBuilder<Station?>(
        future: _stationFuture,
        builder: (ctx, stSnap) {
          if (stSnap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final station = stSnap.data;
          if (station == null) {
            return const Center(child: Text('No station found'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              final freshStation = await _loadStation();
              final freshOrders  = await _fetchAssignedOrders();
              setState(() {
                _stationFuture = Future.value(freshStation);
                _ordersFuture  = Future.value(freshOrders);
                // if a destination was tapped, recompute route
                if (widget.destination != null && freshStation != null) {
                  _getRouteFromApi(
                    LatLng(freshStation.lat, freshStation.lng),
                    widget.destination!,
                  );
                }
              });
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height -
                        (showHeader ? 83 : 0) -
                        (showNav   ? 70 : 0),
                    child: FutureBuilder<List<OrderLocation>>(
                      future: _ordersFuture,
                      builder: (ctx, orSnap) {
                        if (orSnap.connectionState != ConnectionState.done) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (orSnap.hasError) {
                          return Center(child: Text('Error: ${orSnap.error}'));
                        }

                        final orders = orSnap.data!;
                        // center map first time
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _mapCtl.move(LatLng(station.lat, station.lng), 13.0);
                        });

                        return FlutterMap(
                          mapController: _mapCtl,
                          options: MapOptions(
                            initialCenter: LatLng(station.lat, station.lng),
                            initialZoom: 13.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            ),
                            if (_routePoints.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: _routePoints,
                                    strokeWidth: 8,
                                    color: const Color(0xFF455567),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(station.lat, station.lng),
                                  width: 45,
                                  height: 45,
                                  child: Image.asset('images/store_tag1.png'),
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: orders.map((o) {
                                return Marker(
                                  point: LatLng(o.latitude, o.longitude),
                                  width: 40,
                                  height: 40,
                                  child:
                                      Image.asset('images/customer_tag1.png'),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ─── ORDERS TAB ────────────────────────
      const RiderOrders(),

      // ─── PROFILE TAB ───────────────────────
      const RiderProfile(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFEC),
      body: Stack(
        children: [
          if (showHeader)
            const Positioned(top: 50, left: 0, right: 0, child: AppHeader()),
          Positioned(
            top: showHeader ? 83 : 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: !showHeader,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: showNav ? 70 : 0,
                    child: tabs[_selectedIndex],
                  ),
                  if (showNav)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 30,
                      child: CustomBottomNavBarRider(
                        selectedIndex: _selectedIndex,
                        onItemTapped: _onItemTapped,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
