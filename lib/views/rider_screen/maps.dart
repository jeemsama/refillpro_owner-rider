import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/owner_screen/orders.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class Maps extends StatefulWidget {
  const Maps({super.key});

  @override
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  int _selectedIndex = 1;

  // All your tab screens here
  final List<Widget> _screens = const [
    HomeContent(), // extract your Home screen content into a widget
    MapsContent(),
    OrdersContent(),
    ProfileContent(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1EFEC),
      body: Stack(
        children: [
          // Header at top (outside SafeArea)
          const Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: AppHeader(),
          ),
          
          // Main content and navbar inside SafeArea
          Positioned(
            top: 83, // Adjust based on your header height
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false, // Don't apply top safe area as header is outside
              child: Stack(
                children: [
                  // Main content
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    bottom: 97, // Adjust based on navbar height + bottom margin
                    child: _screens[_selectedIndex],
                  ),
                  
                  // Bottom navigation bar positioned at the bottom inside SafeArea
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 30,
                    child: CustomBottomNavBar(
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



class MapsContent extends StatelessWidget {
  const MapsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1EFEC),
      alignment: Alignment.center,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(17.6132, 121.7270), // Tuguegarao City, Philippines coordinates
          initialZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(17.6132, 121.7270), // Tuguegarao City, Philippines
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
