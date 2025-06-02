import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/owner_screen/add_rider.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/maps.dart';
import 'package:refillpro_owner_rider/views/owner_screen/orders.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';
// import 'package:refillpro_owner_rider/views/compact_delivery_details_widget.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;

  // All your tab screens here
  final List<Widget> _screens = const [
    HomeContent(),   // Extracted content
    MapsContent(),
    OrdersContent(),
    Profile(),       // Use your Profile widget
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Don’t show AppHeader on Profile tab (index 3)
    final bool showHeader = _selectedIndex != 3;
    // Don’t show bottom navbar on Profile tab (index 3)
    final bool showNavbar = _selectedIndex != 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFEC),
      body: Stack(
        children: [
          // 1) The global AppHeader (positioned at the very top)
          if (showHeader)
            const Positioned(top: 50, left: 0, right: 0, child: AppHeader()),

          // 2) The main content (HomeContent, MapsContent, etc.)
          Positioned(
            top: showHeader ? 83 : 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: !showHeader,
              child: Stack(
                children: [
                  // 2a) The selected screen’s content
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: showNavbar ? 70 : 0,
                    child: _screens[_selectedIndex],
                  ),

                  // 2b) Bottom nav bar
                  if (showNavbar)
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

// Shop Status Button remains the same as before
class ShopStatusButton extends StatefulWidget {
  const ShopStatusButton({super.key});

  @override
  State<ShopStatusButton> createState() => _ShopStatusButtonState();
}

class _ShopStatusButtonState extends State<ShopStatusButton> {
  bool isShopOpen = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScaleFactor = screenWidth / 401;
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
        shadowColor: const Color(0x3F000000),
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

// Fetch the shop name from your API (unchanged)
Future<String> _fetchShopName() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final res = await http.get(
    Uri.parse('http://192.168.1.17:8000/api/owner/profile'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );
  if (res.statusCode == 200) {
    final body = jsonDecode(res.body);
    return body['shop_name'] as String;
  } else {
    throw Exception('Failed to load shop name');
  }
}


// ───────────────────────────────────────────────────────────────────────
// Here’s the modified HomeContent:
// ───────────────────────────────────────────────────────────────────────
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // Currently selected year (default to current year)
  int selectedYear = DateTime.now().year;

  // Example list of years; expand or fetch from your backend if needed
  final List<int> availableYears = [
    DateTime.now().year - 2,
    DateTime.now().year - 1,
    DateTime.now().year,
  ];

  @override
  Widget build(BuildContext context) {
    // 1) Screen dimensions & scaling helpers
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final widthScaleFactor = screenWidth / 401;

    double w(double value) => value * widthScaleFactor;
    double h(double value) => value * widthScaleFactor;
    double fontSize(double value) => value * widthScaleFactor;

    // Build data for the currently selected year
    final List<_MonthlyStat> monthlyStats = _getMonthlyStatsForYear(selectedYear);

    return Container(
      color: const Color(0xFFF1EFEC),
      width: screenWidth,
      height: screenHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1) FIXED HEADER ROW ───────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(left: w(20), right: w(20), top: h(10)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<String>(
                  future: _fetchShopName(),
                  builder: (context, snapshot) {
                    final name = snapshot.data;
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Hi, …',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize(20),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                              color: const Color.fromRGBO(0, 0, 0, 0.25),
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
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                              color: const Color.fromRGBO(0, 0, 0, 0.25),
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
                              offset: const Offset(0, 4),
                              blurRadius: 4,
                              color: const Color.fromRGBO(0, 0, 0, 0.25),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
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
                    shadowColor: const Color(0x3F000000),
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

          SizedBox(height: h(10)),

          // ─── 2) YEAR PICKER DROPDOWN ───────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w(20)),
            child: Row(
              children: [
                Text(
                  'Select Year:',
                  style: TextStyle(
                    fontSize: fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(width: w(8)),
                DropdownButton<int>(
                  value: selectedYear,
                  icon: Icon(Icons.arrow_drop_down, size: fontSize(20)),
                  items: availableYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(
                        '$year',
                        style: TextStyle(
                          fontSize: fontSize(14),
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newYear) {
                    if (newYear == null) return;
                    setState(() {
                      selectedYear = newYear;
                      // In a real app, fetch new data for this year here
                    });
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: h(15)),

          // ─── 3) SCROLLABLE CONTENT BELOW THE HEADER ─────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: w(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── A) BAR CHART: MONTHLY EARNINGS ───────────────────────
                  Text(
                    'Your Monthly Earnings ($selectedYear)',
                    style: TextStyle(
                      fontSize: fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: h(8)),

                  Container(
                    width: screenWidth - w(30),
                    height: h(200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SfCartesianChart(
                      margin: EdgeInsets.only(top: h(10), left: w(10), right: w(10)),
                      primaryXAxis: CategoryAxis(
                        labelStyle: TextStyle(fontSize: fontSize(10)),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        labelFormat: '₱{value}',
                        interval: 5000, // adjust if your earnings exceed 60k
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(size: 0),
                        labelStyle: TextStyle(fontSize: fontSize(10)),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: '₱point.y',
                        header: '',
                        textStyle: TextStyle(fontSize: fontSize(12)),
                      ),
                      series: <ColumnSeries<_MonthlyStat, String>>[
                        ColumnSeries<_MonthlyStat, String>(
                          dataSource: monthlyStats,
                          xValueMapper: (_MonthlyStat stat, _) => stat.month,
                          yValueMapper: (_MonthlyStat stat, _) => stat.earnings,
                          color: const Color(0xFF5CB338),
                          width: 0.6,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(
                              fontSize: fontSize(10),
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                            labelAlignment: ChartDataLabelAlignment.top,
                            labelPosition: ChartDataLabelPosition.outside,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h(24)),

                  // ─── B) PIE CHART: MONTHLY ORDERS ──────────────────────────
                  Text(
                    'Your Monthly Orders Distribution ($selectedYear)',
                    style: TextStyle(
                      fontSize: fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: h(8)),

                  Container(
                    width: screenWidth - w(30),
                    height: h(200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: SfCircularChart(
                      margin: EdgeInsets.zero,
                      legend: Legend(
                        isVisible: true,
                        height: '100%',
                        overflowMode: LegendItemOverflowMode.wrap,
                        position: LegendPosition.bottom,
                        textStyle: TextStyle(
                          fontSize: fontSize(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        format: '{point.x}: {point.y}',
                        textStyle: TextStyle(fontSize: fontSize(12)),
                      ),
                      series: <PieSeries<_MonthlyStat, String>>[
                        PieSeries<_MonthlyStat, String>(
                          dataSource: monthlyStats,
                          xValueMapper: (_MonthlyStat stat, _) => stat.month,
                          yValueMapper: (_MonthlyStat stat, _) => stat.orders,
                          dataLabelMapper: (_MonthlyStat stat, _) => '${stat.month}: ${stat.orders}',
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(
                              fontSize: fontSize(10),
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          explode: true,
                          radius: '80%',
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: h(24)),

                  // ─── C) EXTRA CONTENT (if desired) ────────────────────────────
                  const CompactDeliveryDetailsWidget(),
                  SizedBox(height: h(100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Generate dummy data for January→December for the selected year.
  // In production, replace this with an async fetch to your backend that returns:
  //   • monthly earnings (double)
  //   • monthly orders (int)
  // for each month of that year.
  List<_MonthlyStat> _getMonthlyStatsForYear(int year) {
    final isCurrentYear = (year == DateTime.now().year);
    return <_MonthlyStat>[
      _MonthlyStat('Jan', (isCurrentYear ? 8000 : 8500), (isCurrentYear ? 12 : 10)),
      _MonthlyStat('Feb', (isCurrentYear ? 9000 : 10500), (isCurrentYear ? 14 : 11)),
      _MonthlyStat('Mar', (isCurrentYear ? 10000 : 9800), (isCurrentYear ? 18 : 15)),
      _MonthlyStat('Apr', (isCurrentYear ? 11000 : 11200), (isCurrentYear ? 20 : 17)),
      _MonthlyStat('May', (isCurrentYear ? 9500 : 9000), (isCurrentYear ? 16 : 14)),
      _MonthlyStat('Jun', (isCurrentYear ? 12000 : 12500), (isCurrentYear ? 22 : 19)),
      _MonthlyStat('Jul', (isCurrentYear ? 10000 : 10200), (isCurrentYear ? 18 : 16)),
      _MonthlyStat('Aug', (isCurrentYear ? 11500 : 10800), (isCurrentYear ? 21 : 17)),
      _MonthlyStat('Sep', (isCurrentYear ? 9800 : 9500), (isCurrentYear ? 17 : 13)),
      _MonthlyStat('Oct', (isCurrentYear ? 12300 : 11800), (isCurrentYear ? 23 : 20)),
      _MonthlyStat('Nov', (isCurrentYear ? 10700 : 10500), (isCurrentYear ? 19 : 16)),
      _MonthlyStat('Dec', (isCurrentYear ? 13000 : 12500), (isCurrentYear ? 24 : 21)),
    ];
  }
}

/// Simple data‐model class for monthly stats.
class _MonthlyStat {
  final String month;     // e.g. 'Jan', 'Feb', … 'Dec'
  final double earnings;  // e.g. 12000.0
  final int orders;       // e.g. 20
  _MonthlyStat(this.month, this.earnings, this.orders);
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
      final url = Uri.parse('http://192.168.1.17:8000/api/owner/shop-details');
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
      final url = Uri.parse('http://192.168.1.17:8000/api/owner/shop-details');
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
