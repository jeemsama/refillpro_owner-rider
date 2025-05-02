import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner screen/home.dart';
import 'package:refillpro_owner_rider/views/owner screen/maps.dart'; // Import for navigation
import 'package:refillpro_owner_rider/views/owner screen/orders.dart'; // Import for navigation


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final int _selectedIndex = 3; // Profile tab is selected (index 3)
  
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Orders()),
        );
        break;
      case 3: 
        // Already on Profile page, do nothing
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
                    'Profile Page',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // Add your profile content here
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