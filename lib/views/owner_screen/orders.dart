import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/maps.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  int _selectedIndex = 2;

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








class OrdersContent extends StatelessWidget {
  const OrdersContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    
    // Calculate scale factor based on design width (401)
    final widthScaleFactor = screenWidth / 401;
    
    // Function to scale dimensions
    double w(double value) => value * widthScaleFactor;
    double h(double value) => value * widthScaleFactor; // Using same scale for height for proportional scaling
    
    // Function to scale text
    
    return Container(
      color: const Color(0xFFF1EFEC),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: h(15), horizontal: w(0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              OrderCard(
                widthScaleFactor: widthScaleFactor,
                customerName: 'Jaymark Ancheta',
                phoneNumber: '0912-3234-234',
                orderType: 'Borrow gallon',
                message: 'Message here Message hereMessage hereMessage hereMessage hereMessage',
                price: '₱0.0',
                status: 'Pending',
              ),
              // You can add more OrderCard widgets here
            ],
          ),
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final double widthScaleFactor;
  final String customerName;
  final String phoneNumber;
  final String orderType;
  final String message;
  final String price;
  final String status;

  const OrderCard({
    required this.widthScaleFactor,
    required this.customerName,
    required this.phoneNumber,
    required this.orderType,
    required this.message,
    required this.price,
    required this.status,
    super.key,
  });

  // Helper functions to scale dimensions
  double w(double value) => value * widthScaleFactor;
  double h(double value) => value * widthScaleFactor;
  double fontSize(double value) => value * widthScaleFactor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: h(10), horizontal: w(10)),
      child: SizedBox(
        width: w(397),
        height: h(199),
        child: Stack(
          children: [
            // Main card background
            Positioned(
              left: w(5.5),
              top: 0,
              child: Container(
                width: w(370),
                height: h(199),
                decoration: ShapeDecoration(
                  color: const Color(0xFF1F2937),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w(10)),
                  ),
                ),
              ),
            ),
            
            // Regular gallon image and x2 text
            Positioned(
              left: w(48),
              top: h(127),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: w(38),
                    height: h(54),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("images/regular.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: h(-9),
                    child: SizedBox(
                      width: w(12),
                      height: h(9),
                      child: Text(
                        'x2',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize(7),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Dispenser gallon image and x2 text
            Positioned(
              left: w(110),
              top: h(127),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Container(
                    width: w(31),
                    height: h(54),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("images/dispenser.png"),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: h(-9),
                    child: SizedBox(
                      width: w(12),
                      height: h(9),
                      child: Text(
                        'x2',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize(7),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Price text
            Positioned(
              left: w(320),
              top: h(171),
              child: SizedBox(
                width: w(37),
                height: h(16),
                child: Text(
                  price,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize(14),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            
            // Status text
            Positioned(
              left: w(290),
              top: h(17),
              child: SizedBox(
                width: w(64.66),
                height: h(14),
                child: Row(
                  children: [
                    Text(
                      status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize(13),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(width: w(2)),
                    Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: w(10),
                    ),
                  ],
                ),
              ),
            ),
            
            // Location text
            Positioned(
              left: w(3),
              top: h(59),
              child: SizedBox(
                width: w(157),
                height: h(14),
                child: Text(
                  'Tap to view location',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize(7),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            
            // Customer name
            Positioned(
              left: w(0),
              top: h(10),
              child: SizedBox(
                width: w(212),
                height: h(30),
                child: Text(
                  customerName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize(13),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            // Phone number
            Positioned(
              left: w(5),
              top: h(34),
              child: SizedBox(
                width: w(157),
                height: h(14),
                child: Text(
                  phoneNumber,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize(10),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            
            // Order type
            Positioned(
              left: w(3),
              top: h(45),
              child: SizedBox(
                width: w(157),
                height: h(14),
                child: Text(
                  orderType,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize(10),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
            
            // Accept button (green)
            Positioned(
              left: w(240),
              top: h(74),
              child: GestureDetector(
                onTap: () {
                  // Add accept action here
                  debugPrint('Order accepted');
                },
                child: Container(
                  width: w(50),
                  height: h(50),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF5CB338),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w(5)),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: w(24),
                    ),
                  ),
                ),
              ),
            ),
            
            // Reject button (red)
            Positioned(
              left: w(308),
              top: h(74),
              child: GestureDetector(
                onTap: () {
                  // Add reject action here
                  debugPrint('Order rejected');
                },
                child: Container(
                  width: w(50),
                  height: h(50),
                  decoration: ShapeDecoration(
                    color: const Color(0xFFA62C2C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w(5)),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: w(24),
                    ),
                  ),
                ),
              ),
            ),
            
            // Message text
            Positioned(
              left: w(48),
              top: h(77),
              child: SizedBox(
                width: w(129),
                height: h(47),
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize(7),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}