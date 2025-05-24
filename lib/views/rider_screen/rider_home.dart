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
import 'package:refillpro_owner_rider/views/rider_screen/rider_orders.dart';

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
  const RiderHome({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _RiderHomeState createState() => _RiderHomeState();
}

class _RiderHomeState extends State<RiderHome> {
  final MapController _mapCtl = MapController();
  Station? _station;
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStation();
  }

  Future<void> _loadStation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ownerId = prefs.getInt('owner_id');
      if (ownerId == null) throw 'Please log in again.';

      final resp = await http.get(
        Uri.parse('http://192.168.1.6:8000/api/v1/refill-stations'),
        headers: {'Accept': 'application/json'},
      );
      if (resp.statusCode != 200) {
        throw 'Failed to fetch stations (${resp.statusCode})';
      }

      final list = jsonDecode(resp.body) as List<dynamic>;
      final match = list.firstWhere(
        (e) => e['owner_id'] == ownerId,
        orElse: () => null,
      );
      if (match == null) throw 'No station found for your account.';

      _station = Station.fromJson(match as Map<String, dynamic>);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapCtl.move(LatLng(_station!.lat, _station!.lng), 15.0);
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // if switching back to map, recenter
    if (index == 0 && _station != null) {
      _mapCtl.move(LatLng(_station!.lat, _station!.lng), 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Profile tab is index 2
    final bool showHeader = _selectedIndex != 2;
    final bool showNavbar = _selectedIndex != 2;

    // Your three tab widgets
    final tabs = <Widget>[
      // Map
      if (_loading)
        const Center(child: CircularProgressIndicator())
      else if (_error != null)
        Center(
          child: Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        )
      else if (_station == null)
        const Center(child: Text('No station found'))
      else
        FlutterMap(
          mapController: _mapCtl,
          options: MapOptions(
            initialCenter: LatLng(_station!.lat, _station!.lng),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            MarkerLayer(markers: [
              Marker(
                point: LatLng(_station!.lat, _station!.lng),
                width: 45,
                height: 45,
                child: Image.asset('images/store_tag1.png', width: 45, height: 45),
              )
            ]),
          ],
        ),

      // Orders
      const RiderOrders(),

      // Profile
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
                  // main content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: showNavbar ? 70 : 0,
                    child: tabs[_selectedIndex],
                  ),

                  // bottom nav
                  if (showNavbar)
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
