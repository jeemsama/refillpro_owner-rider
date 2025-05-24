// lib/views/owner_screen/maps.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/owner_screen/orders.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';

class Maps extends StatefulWidget {
  const Maps({super.key});
  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  int _selectedIndex = 1;
  static const _screens = <Widget>[
    HomeContent(),
    MapsContent(),
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
          top: 83, left: 0, right: 0, bottom: 0,
          child: SafeArea(
            top: false,
            child: Stack(children: [
              Positioned(
                top: 20, left: 0, right: 0, bottom: 97,
                child: _screens[_selectedIndex],
              ),
              Positioned(
                left: 0, right: 0, bottom: 30,
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

/// Mini-model for your shop
class ShopDetail {
  final int id;
  final int ownerId;
  final String shopName;
  final double lat, lng;

  ShopDetail({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.lat,
    required this.lng,
  });

  factory ShopDetail.fromJson(Map<String, dynamic> j) {
    return ShopDetail(
      id: j['id'] as int,
      ownerId: j['owner_id'] as int,
      shopName: j['shop_name'] as String,
      lat: double.parse(j['latitude'].toString()),
      lng: double.parse(j['longitude'].toString()),
    );
  }
}

class MapsContent extends StatefulWidget {
  const MapsContent({super.key});
  @override
  State<MapsContent> createState() => _MapsContentState();
}

class _MapsContentState extends State<MapsContent> {
  final MapController _mapController = MapController();
  bool _loading = true;
  String? _error;
  ShopDetail? _mine;

  @override
  void initState() {
    super.initState();
    _loadMyShop();
  }

  Future<void> _loadMyShop() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final myOwnerId = prefs.getInt('owner_id');
      if (myOwnerId == null) {
        throw 'no owner_id saved – please register/log in first';
      }

      final uri = Uri.parse('http://192.168.1.6:8000/api/v1/refill-stations');
      final resp = await http.get(uri, headers: {
        'Accept': 'application/json',
      });

      if (resp.statusCode != 200) {
        throw 'Failed to load stations (status ${resp.statusCode})';
      }

      final List jsonList = json.decode(resp.body) as List;
      final matches = jsonList
          .map((e) => ShopDetail.fromJson(e as Map<String, dynamic>))
          .where((s) => s.ownerId == myOwnerId)
          .toList();

      if (matches.isEmpty) {
        throw 'No approved station found for owner_id=$myOwnerId';
      }
      _mine = matches.first;

      // center the map:
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(_mine!.lat, _mine!.lng), 15.0);
      });

      setState(() { _loading = false; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_mine == null) {
      return const Center(child: Text('No station data'));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(_mine!.lat, _mine!.lng),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(_mine!.lat, _mine!.lng),
              width: 50,
              height: 50,
              child: Image.asset(
                'images/store_tag1.png',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
