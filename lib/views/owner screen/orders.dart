import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner screen/home.dart';
import 'package:refillpro_owner_rider/views/owner screen/maps.dart'; // Import for navigation// Import for navigation
import 'package:refillpro_owner_rider/views/owner screen/profile.dart'; 

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  final int _selectedIndex = 2; // Orders/Cart tab is selected (index 2)
  
  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Don't navigate if already on this page
    
    // Navigate to the appropriate page based on index
    switch (index) {
      case 0: 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
        break;
      case 1: 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Maps()),
        );
        break;
      case 2: 
        // Already on Orders page, do nothing
        break;
      case 3: 
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Profile()),
        );
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF1EFEC),
      body: Stack(
        children: [
          // Header positioned at the top
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppHeader(),
          ),
          
          // Main content with padding to avoid overlap with header
          Padding(
            padding: const EdgeInsets.only(top: 78.0), // Same as header height
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Orders Page',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Add your orders content here
                ],
              ),
            ),
          ),
          
          // Bottom navigation bar positioned at the bottom with some padding
          Positioned(
            left: 0,
            right: 0,
            bottom: 30, // Distance from bottom of screen
            child: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
      ),
    );
  }
}