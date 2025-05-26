import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/add_rider.dart';
import 'package:refillpro_owner_rider/views/owner_screen/maps.dart';
import 'package:refillpro_owner_rider/views/owner_screen/orders.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  // All your tab screens here
  final List<Widget> _screens = const [
    HomeContent(), // extract your Home screen content into a widget
    MapsContent(),
    OrdersContent(),
    Profile(), // Changed from ProfileContent to Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don't show header on the Profile tab (index 3)
    final bool showHeader = _selectedIndex != 3;

    // Don't show navbar on the Profile tab (index 3)
    final bool showNavbar = _selectedIndex != 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFEC),
      body: Stack(
        children: [
          // Header at top (outside SafeArea) - only show if not on Profile tab
          if (showHeader)
            const Positioned(top: 50, left: 0, right: 0, child: AppHeader()),

          // Main content and navbar inside SafeArea
          Positioned(
            // Adjust top position based on whether header is shown
            top: showHeader ? 83 : 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: !showHeader, // Apply top safe area if header is not shown
              child: Stack(
                children: [
                  // Main content - extend to bottom of screen
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: showNavbar ? 70 : 0, // Reduced space above navbar
                    child: _screens[_selectedIndex],
                  ),

                  // Bottom navigation bar - only show if not on Profile tab
                  if (showNavbar)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom:
                          30, // Changed from 30 to 0 to remove space below navbar
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

// Shop Status Button that toggles between open and closed
class ShopStatusButton extends StatefulWidget {
  const ShopStatusButton({super.key});

  @override
  State<ShopStatusButton> createState() => _ShopStatusButtonState();
}

class _ShopStatusButtonState extends State<ShopStatusButton> {
  bool isShopOpen = true;

  @override
  Widget build(BuildContext context) {
    // Get the scale factor for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScaleFactor = screenWidth / 401;

    // Helper functions for scaling
    double w(double value) => value * widthScaleFactor;
    double fontSize(double value) => value * widthScaleFactor;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          isShopOpen = !isShopOpen;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isShopOpen ? const Color(0xFF5CB338) : Colors.red,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: w(10), vertical: w(5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        shadowColor: Color(0x3F000000),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isShopOpen ? 'SHOP OPEN' : 'SHOP CLOSED',
            style: TextStyle(
              fontSize: fontSize(15),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            isShopOpen ? 'Tap to close' : 'Tap to open',
            style: TextStyle(
              fontSize: fontSize(8),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

Future<String> _fetchShopName() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';

  final res = await http.get(
    Uri.parse('http://192.168.1.6:8000/api/owner/profile'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );
  if (res.statusCode == 200) {
    final body = jsonDecode(res.body);
    return body['shop_name'] as String;
  } else {
    throw Exception('Failed to load shop name');
  }
}

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate scale factor based on design width (401)
    final widthScaleFactor = screenWidth / 401;

    // Function to scale dimensions
    double w(double value) => value * widthScaleFactor;
    double h(double value) =>
        value *
        widthScaleFactor; // Using same scale for height for proportional scaling

    // Function to scale text
    double fontSize(double value) => value * widthScaleFactor;

    return Container(
      color: const Color(0xFFF1EFEC),
      width: screenWidth,
      height: screenHeight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: w(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with greeting and add rider button
              Padding(
                padding: EdgeInsets.only(top: h(10)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<String>(
                      future: _fetchShopName(),
                      builder: (context, snapshot) {
                        final name = snapshot.data;
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Text(
                            'Hi, …',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize(20),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 4),
                                  blurRadius: 4,
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                ),
                              ],
                            ),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Hi, owner',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize(20),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 4),
                                  blurRadius: 4,
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return Text(
                            'Hi, $name',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: fontSize(20),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 4),
                                  blurRadius: 4,
                                  color: Color.fromRGBO(0, 0, 0, 0.25),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                    ),

                    // Add rider button
                    ElevatedButton(
                      onPressed: () {
                        // Add rider functionality
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddRider(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CB338),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: w(10),
                          vertical: h(5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 4,
                        shadowColor: Color(0x3F000000),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: fontSize(12)),
                          SizedBox(width: w(4)),
                          Text(
                            'Add rider',
                            style: TextStyle(
                              fontSize: fontSize(10),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: h(15)),

              // Main blue card with shop status
              Stack(
                children: [
                  // Main blue container
                  Container(
                    width: screenWidth - w(40),
                    height: h(163),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF455567),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Current month amount
                        Positioned(
                          left: w(28),
                          top: h(17),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₱0.0',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize(24),
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: h(1)),
                              Text(
                                'May 2025',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: fontSize(10),
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Divider lines
                        Positioned(
                          left: w(120),
                          top: h(102),
                          child: Opacity(
                            opacity: 0.50,
                            child: Container(
                              width: w(2),
                              height: h(49),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: w(250),
                          top: h(102),
                          child: Opacity(
                            opacity: 0.50,
                            child: Container(
                              width: w(2),
                              height: h(49),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // April amount
                        Positioned(
                          left: w(22),
                          top: h(117),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.50,
                                child: Text(
                                  '₱10,000.00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(14),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(height: h(2)),
                              Opacity(
                                opacity: 0.50,
                                child: Text(
                                  'April 2025',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(6),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // March amount
                        Positioned(
                          left: w(152),
                          top: h(117),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.50,
                                child: Text(
                                  '₱10,000.00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(14),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(height: h(2)),
                              Opacity(
                                opacity: 0.50,
                                child: Text(
                                  'March 2025',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(6),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // February amount
                        Positioned(
                          left: w(273),
                          top: h(117),
                          child: Column(
                            children: [
                              Opacity(
                                opacity: 0.50,
                                child: Text(
                                  '₱10,000.00',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(14),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SizedBox(height: h(2)),
                              Opacity(
                                opacity: 0.50,
                                child: Text(
                                  'February 2025',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(6),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Shop open/close button - positioned at the top right of the card
                  Positioned(right: w(8), top: h(8), child: ShopStatusButton()),
                ],
              ),

              SizedBox(height: h(15)),

              // Three cards in row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Total Orders card
                  Container(
                    width: (screenWidth - w(80)) / 3,
                    height: h(87),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF1F2937),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '112',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(24),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Text(
                          'Total Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(10),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pending Orders card
                  Container(
                    width: (screenWidth - w(80)) / 3,
                    height: h(87),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF455567),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '5',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(24),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Text(
                          'Pending Orders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(10),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Riders card
                  Container(
                    width: (screenWidth - w(80)) / 3,
                    height: h(87),
                    decoration: ShapeDecoration(
                      color: const Color(0xFF1F2937),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(24),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: h(5)),
                        Text(
                          'Riders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(10),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Below the Row of cards
              SizedBox(height: h(15)),

              // Your custom widget - EditDetailsWidget (if needed)
              CompactDeliveryDetailsWidget(),

              // Add some space at the bottom for the navbar
              SizedBox(height: h(100)),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactDeliveryDetailsWidget extends StatefulWidget {
  const CompactDeliveryDetailsWidget({super.key});

  @override
  State<CompactDeliveryDetailsWidget> createState() =>
      _CompactDeliveryDetailsWidgetState();
}

class _CompactDeliveryDetailsWidgetState
    extends State<CompactDeliveryDetailsWidget> {
  bool _isLoading = false;

  // State for delivery time selection
  final List<String> _deliveryTimes = [
    '7AM',
    '8AM',
    '9AM',
    '10AM',
    '11AM',
    '12PM',
    '1PM',
    '2PM',
    '3PM',
    '4PM',
  ];
  final Set<String> _selectedTimes = {};

  // State for collection day selection
  final List<String> _collectionDays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];
  final Set<String> _selectedDays = {};

  // State for gallon prices - fixed product types with editable prices
  final TextEditingController _regularGallonPriceController =
      TextEditingController(text: '₱50.00');
  final TextEditingController _dispenserGallonPriceController =
      TextEditingController(text: '₱50.00');

  @override
  void initState() {
    super.initState();
    // Fetch existing shop details when component loads
    _fetchShopDetails();
  }

  @override
  void dispose() {
    _regularGallonPriceController.dispose();
    _dispenserGallonPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchShopDetails() async {
    setState(() => _isLoading = true);
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Request shop details from backend
      final url = Uri.parse('http://192.168.1.6:8000/api/owner/shop-details');
      final response = await http
          .get(
            url,
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final shopDetails = data['data'] as Map<String, dynamic>? ?? {};

        // Update UI with fetched data
        setState(() {
          // Update delivery time slots
          final timeSlots =
              shopDetails['delivery_time_slots'] as List<dynamic>? ?? [];
          _selectedTimes.clear();
          for (final time in timeSlots) {
            _selectedTimes.add(time.toString());
          }

          // Update collection days
          final collectionDays =
              shopDetails['collection_days'] as List<dynamic>? ?? [];
          _selectedDays.clear();
          for (final day in collectionDays) {
            _selectedDays.add(day.toString());
          }

          // Only update prices for the two fixed product types
          final regularPrice = shopDetails['regular_gallon_price'];
          if (regularPrice != null) {
            _regularGallonPriceController.text = '₱${regularPrice.toString()}';
          }

          final dispenserPrice = shopDetails['dispenser_gallon_price'];
          if (dispenserPrice != null) {
            _dispenserGallonPriceController.text =
                '₱${dispenserPrice.toString()}';
          }
        });
      } else {
        // If 404 or other error, we'll initialize with defaults (already done in constructor)
        debugPrint('Failed to fetch shop details: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching shop details: $e');
      // Don't show error to user - just use defaults
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    // Calculate scale factor based on design width (401)
    final widthScaleFactor = screenWidth / 401;

    // Function to scale dimensions
    double w(double value) => value * widthScaleFactor;
    double h(double value) => value * widthScaleFactor;

    // Function to scale text
    double fontSize(double value) => value * widthScaleFactor;

    return Container(
      width: screenWidth - w(40),
      decoration: ShapeDecoration(
        color: Color(0xffF1EFEC),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w(15), vertical: h(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edit details header
            Text(
              'Edit details',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize(18),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: h(12)),

            // Preferred delivery time section
            Text(
              'Preffered delivery time',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize(16),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: h(8)),

            // Delivery time buttons in a wrapped layout
            Wrap(
              spacing: w(6),
              runSpacing: h(8),
              children:
                  _deliveryTimes.map((time) {
                    final isSelected = _selectedTimes.contains(time);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTimes.remove(time);
                          } else {
                            _selectedTimes.add(time);
                          }
                        });
                      },
                      child: Container(
                        width: w(60),
                        height: h(28),
                        decoration: ShapeDecoration(
                          color:
                              isSelected
                                  ? const Color(0xFF5CB338)
                                  : const Color(0xFF1F2937),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side:
                                isSelected
                                    ? const BorderSide(
                                      color: Colors.blue,
                                      width: 2.0,
                                    )
                                    : BorderSide.none,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            time,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: fontSize(12),
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: h(12)),

            // Collection day section
            Text(
              'Collection day',
              style: TextStyle(
                color: Colors.black,
                fontSize: fontSize(16),
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: h(5)),

            // Collection day selection - more compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  _collectionDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return Column(
                      children: [
                        Container(
                          width: w(18),
                          height: h(18),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? const Color(0xFF1F2937)
                                    : Colors.white,
                            border: Border.all(
                              color: const Color(0xFF1F2937),
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedDays.remove(day);
                                } else {
                                  _selectedDays.add(day);
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(height: h(2)),
                        Text(
                          day,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: fontSize(10),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),

            SizedBox(height: h(15)),

            // Fixed product types: Regular and Dispenser gallons side by side
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Regular gallon (fixed product)
                _buildGallonItem(
                  'images/regular.png',
                  _regularGallonPriceController,
                  screenWidth / 2 - w(50),
                ),

                // Dispenser gallon (fixed product)
                _buildGallonItem(
                  'images/dispenser.png',
                  _dispenserGallonPriceController,
                  screenWidth / 2 - w(50),
                ),
              ],
            ),

            SizedBox(height: h(15)),

            // Save button
            Center(
              child: ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          await _saveDetails();
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w(10)),
                  ),
                  minimumSize: Size(w(96), h(36)),
                  elevation: 2,
                  disabledBackgroundColor: Colors.grey,
                ),
                child:
                    _isLoading
                        ? SizedBox(
                          width: w(20),
                          height: h(20),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.0,
                          ),
                        )
                        : Text(
                          'Save',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontSize(14),
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallonItem(
    String imagePath,
    TextEditingController controller,
    double width,
  ) {
    // Get scale factors for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScaleFactor = screenWidth / 401;

    // Scale functions
    double h(double value) => value * widthScaleFactor;
    double fontSize(double value) => value * widthScaleFactor;

    return Container(
      width: width,
      height: h(180), // Reduced height to make it more compact
      decoration: ShapeDecoration(
        color: const Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Image container
          Container(
            padding: EdgeInsets.only(top: h(10)),
            height: h(135),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),

          // Price input
          Padding(
            padding: EdgeInsets.only(bottom: h(10)),
            child: Container(
              width: width * 0.8,
              height: h(26),
              decoration: ShapeDecoration(
                color: const Color(0xFFD9D9D9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: Colors.black,
                  fontSize: fontSize(15),
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w600,
                  height: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDetails() async {
    setState(() => _isLoading = true);
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Format prices - strip currency symbol and convert to double
      final regularPrice =
          double.tryParse(
            _regularGallonPriceController.text.replaceAll('₱', '').trim(),
          ) ??
          50.0;

      final dispenserPrice =
          double.tryParse(
            _dispenserGallonPriceController.text.replaceAll('₱', '').trim(),
          ) ??
          50.0;

      // Create payload based on OwnerShopDetails model with fixed product types
      final payload = {
        'delivery_time_slots': _selectedTimes.toList(),
        'collection_days': _selectedDays.toList(),
        'has_regular_gallon': true, // Always true - fixed product
        'regular_gallon_price': regularPrice,
        'has_dispenser_gallon': true, // Always true - fixed product
        'dispenser_gallon_price': dispenserPrice,
        'has_small_gallon': false, // Always false - product not offered
        'small_gallon_price': 30.0, // Default value in case backend requires it
      };

      debugPrint('Sending shop details: $payload');

      // Send to backend
      final url = Uri.parse('http://192.168.1.6:8000/api/owner/shop-details');
      final response = await http
          .post(
            url,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shop details saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Parse error message if available
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage =
            responseData['message'] ?? 'Failed to save shop details';
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error saving shop details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
