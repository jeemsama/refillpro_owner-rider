import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:refillpro_owner_rider/views/owner_screen/add_rider.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  // Animation controller for the settings drawer
  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    
    // Set the Profile-specific style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1F2937),
      statusBarIconBrightness: Brightness.light,
    ));

    // Initialize drawer animation controller
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _drawerAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),  // Start from right side (off screen)
      end: Offset.zero,               // End at visible position
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // IMPORTANT: Reset to the default app style when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Default transparent
      statusBarIconBrightness: Brightness.dark, // Default dark icons
    ));
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_isDrawerOpen) {
      _drawerController.reverse();
    } else {
      _drawerController.forward();
    }
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _handleRidersTap() {
    // Handle Riders menu item tap
    _toggleDrawer(); // Close drawer
    // Navigate to Riders page
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRider()));
  }

  void _handleLogoutTap() {
    // Handle Log out menu item tap
    _toggleDrawer(); // Close drawer
    // Implement logout functionality
    // Example: 
    // AuthService.logout();
    // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xff1F2937),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: const Color(0xFF1F2937),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const Home()),
                );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _toggleDrawer, // Toggle the settings drawer
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main profile content
          const ProfileContent(),
          
          // Overlay when drawer is open
          if (_isDrawerOpen || _drawerController.status == AnimationStatus.forward || 
              _drawerController.status == AnimationStatus.reverse)
            Positioned.fill(
              child: GestureDetector(
                onTap: _isDrawerOpen ? _toggleDrawer : null,
                child: Container(
                  color: _isDrawerOpen ? const Color.fromRGBO(0, 0, 0, 0.4) : Colors.transparent,
                ),
              ),
            ),
          
          // Animated Settings Drawer
          SlideTransition(
            position: _drawerAnimation,
            child: Align(
              alignment: Alignment.centerRight,
              child: SettingsDrawer(
                onRidersTap: _handleRidersTap,
                onLogoutTap: _handleLogoutTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Drawer Widget
class SettingsDrawer extends StatelessWidget {
  final Function() onRidersTap;
  final Function() onLogoutTap;

  const SettingsDrawer({
    super.key,
    required this.onRidersTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 319,
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF1F2937),
      child: Stack(
        children: [
          // Settings Title
          Positioned(
            left: 57.60,
            top: 55,
            child: SizedBox(
              width: 189.04,
              height: 36,
              child: Text(
                'Settings',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          
          // Riders Button
          Positioned(
            left: 0,
            top: 116,
            right: 0,
            child: InkWell(
              onTap: onRidersTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const Text(
                  'Riders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Log out Button
          Positioned(
            left: 0,
            top: 144,
            right: 0,
            child: InkWell(
              onTap: onLogoutTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const Text(
                  'Log out',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Logo at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: Image.asset(
                'images/logo1.png',
                width: 35.27,
                height: 42.50,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  String shopName = 'AquaLife';
  String contactNumber = '09275313243';

  bool isEditingShopName = false;
  bool isEditingContactNumber = false;

  late TextEditingController shopNameController;
  late TextEditingController contactNumberController;

  @override
  void initState() {
    super.initState();
    shopNameController = TextEditingController(text: shopName);
    contactNumberController = TextEditingController(text: contactNumber);
  }

  @override
  void dispose() {
    shopNameController.dispose();
    contactNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final widthScaleFactor = screenWidth / 401;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    double w(double value) => value * widthScaleFactor;
    double h(double value) => value * widthScaleFactor;
    double fontSize(double value) => value * widthScaleFactor;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFEC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section
            Container(
              width: double.infinity,
              height: h(170) + topPadding,
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: w(125),
                        height: h(116),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                      Container(
                        width: w(98),
                        height: h(98),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                        child: Icon(
                          Icons.person,
                          size: w(60),
                          color: const Color(0xFFD9D9D9),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 8,
                        child: Container(
                          width: w(24),
                          height: h(24),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit,
                            size: fontSize(14),
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    shopName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize(24),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // Body content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  // Shop name field
                  _buildEditableField(
                    label: 'Shop name',
                    value: shopName,
                    isEditing: isEditingShopName,
                    controller: shopNameController,
                    fontSize: fontSize,
                    onSave: () {
                      setState(() {
                        shopName = shopNameController.text;
                        isEditingShopName = false;
                      });
                    },
                    onEdit: () {
                      setState(() {
                        shopNameController.text = shopName;
                        isEditingShopName = true;
                      });
                    },
                  ),

                  // Contact number field
                  _buildEditableField(
                    label: 'Contact Number',
                    value: contactNumber,
                    isEditing: isEditingContactNumber,
                    controller: contactNumberController,
                    fontSize: fontSize,
                    onSave: () {
                      setState(() {
                        contactNumber = contactNumberController.text;
                        isEditingContactNumber = false;
                      });
                    },
                    onEdit: () {
                      setState(() {
                        contactNumberController.text = contactNumber;
                        isEditingContactNumber = true;
                      });
                    },
                    keyboardType: TextInputType.phone,
                  ),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Pin your shop location',
                        style: TextStyle(
                          fontSize: fontSize(14),
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),

                  // Map
                  Container(
                    width: double.infinity,
                    height: h(180),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2937),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(17.6132, 121.7270),
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
                              point: LatLng(17.6132, 121.7270),
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
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [

                      // Save button (original)
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile updated successfully!')),
                          );
                        },
                        child: Container(
                          width: w(96),
                          height: h(36),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3F000000),
                                blurRadius: 4,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize(14),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required double Function(double) fontSize,
    required VoidCallback onSave,
    required VoidCallback onEdit,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8, right: 12),
                  child: isEditing
                      ? TextField(
                          controller: controller,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            fontSize: fontSize(16),
                            fontWeight: FontWeight.w500,
                          ),
                          keyboardType: keyboardType,
                          autofocus: true,
                          onSubmitted: (_) => onSave(),
                    )
                      : Text(
                          value,
                          style: TextStyle(
                            fontSize: fontSize(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit, size: fontSize(18)),
            onPressed: isEditing ? onSave : onEdit,
          ),
        ],
      ),
    );
  }
}