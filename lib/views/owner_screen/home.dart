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
// Future<String> _fetchShopName() async {
//   final prefs = await SharedPreferences.getInstance();
//   final token = prefs.getString('auth_token') ?? '';
//   final res = await http.get(
//     Uri.parse('http://192.168.1.22:8000/api/owner/profile'),
//     headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
//   );
//   if (res.statusCode == 200) {
//     final body = jsonDecode(res.body);
//     return body['shop_name'] as String;
//   } else {
//     throw Exception('Failed to load shop name');
//   }
// }


// ───────────────────────────────────────────────────────────────────────
// Here’s the modified HomeContent:
// ───────────────────────────────────────────────────────────────────────


class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // 1) Year selection
  int selectedYear = DateTime.now().year;
  final List<int> availableYears = [
    DateTime.now().year - 2,
    DateTime.now().year - 1,
    DateTime.now().year,
  ];

  // 2) State for stats data
  bool isLoading = false;
  String? errorMessage;
  List<_MonthlyStat> monthlyStats = [];

  @override
  void initState() {
    super.initState();
    _loadStatsForYear(selectedYear);
  }

  Future<void> _loadStatsForYear(int year) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      monthlyStats = [];
    });

    try {
      final stats = await _fetchStatsFromApi(year);
      setState(() {
        monthlyStats = stats;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1) Screen dimensions & scaling
    final screenWidth = MediaQuery.of(context).size.width;
    final widthScaleFactor = screenWidth / 401;
    double w(double v) => v * widthScaleFactor;
    double h(double v) => v * widthScaleFactor;
    double fontSize(double v) => v * widthScaleFactor;

    // 2) Filter out any months where orders == 0
    final List<_MonthlyStat> nonZeroMonths =
        monthlyStats.where((stat) => stat.orders > 0).toList();

    return Container(
      color: const Color(0xFFF1EFEC),
      width: screenWidth,
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
                  builder: (c, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        'Hi, …',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize(20),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          shadows: const [
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
                          shadows: const [
                            Shadow(
                              offset: Offset(0, 4),
                              blurRadius: 4,
                              color: Color.fromRGBO(0, 0, 0, 0.25),
                            ),
                          ],
                        ),
                      );
                    } else {
                      final name = snapshot.data!;
                      return Text(
                        'Hi, $name',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: fontSize(20),
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          shadows: const [
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

                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => const AddRider(),
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
                  items: availableYears.map((yr) {
                    return DropdownMenuItem<int>(
                      value: yr,
                      child: Text(
                        '$yr',
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
                    });
                    _loadStatsForYear(newYear);
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: h(15)),

          // ─── 3) SCROLLABLE CONTENT ─────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: w(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show loading spinner or error if needed
                  if (isLoading)
                    Center(child: CircularProgressIndicator())
                  else if (errorMessage != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: h(20)),
                      child: Text(
                        'Error: $errorMessage',
                        style: TextStyle(
                            color: Colors.red, fontSize: fontSize(14)),
                      ),
                    )
                  else ...[
                    // ─── A & B) TWO CHARTS IN A ROW ─────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Left: Monthly Earnings Chart ────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Monthly Earnings ($selectedYear)',
                                style: TextStyle(
                                  fontSize: fontSize(13),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: h(8)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => EnlargeBarChartPage(
                                        monthlyStats: monthlyStats,
                                        year: selectedYear,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: h(200),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: SfCartesianChart(
                                    margin: EdgeInsets.only(
                                      top: h(10),
                                      left: w(10),
                                      right: w(10),
                                    ),
                                    primaryXAxis: CategoryAxis(
                                      labelStyle: TextStyle(fontSize: fontSize(10)),
                                      majorGridLines:
                                          const MajorGridLines(width: 0),
                                    ),
                                    primaryYAxis: NumericAxis(
                                      labelFormat: '₱{value}',
                                      interval: 1000, // adjust to your data
                                      axisLine: const AxisLine(width: 0),
                                      majorTickLines:
                                          const MajorTickLines(size: 0),
                                      labelStyle:
                                          TextStyle(fontSize: fontSize(10)),
                                    ),
                                    tooltipBehavior: TooltipBehavior(
                                      enable: true,
                                      format: '₱point.y',
                                      header: '',
                                      textStyle:
                                          TextStyle(fontSize: fontSize(12)),
                                    ),
                                    series: <ColumnSeries<_MonthlyStat, String>>[
                                      ColumnSeries<_MonthlyStat, String>(
                                        dataSource: monthlyStats,
                                        xValueMapper:
                                            (_MonthlyStat stat, _) =>
                                                stat.month,
                                        yValueMapper:
                                            (_MonthlyStat stat, _) =>
                                                stat.earnings,
                                        color: const Color(0xFF455567),
                                        width: 0.6,
                                        borderRadius:
                                            const BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: w(20)),

                        // ─── Right: Monthly Orders (Pie Chart) ─────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Monthly Orders ($selectedYear)',
                                style: TextStyle(
                                  fontSize: fontSize(13),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: h(8)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => EnlargePieChartPage(
                                        monthlyStats: nonZeroMonths,
                                        year: selectedYear,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  height: h(200),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: SfCircularChart(
                                    margin: EdgeInsets.zero,
                                    legend: Legend(
                                      isVisible: true,
                                      height: '100%',
                                      overflowMode:
                                          LegendItemOverflowMode.wrap,
                                      position: LegendPosition.bottom,
                                      textStyle: TextStyle(
                                        fontSize: fontSize(12),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    tooltipBehavior: TooltipBehavior(
                                      enable: true,
                                      format: '{point.x}: {point.y}',
                                      textStyle:
                                          TextStyle(fontSize: fontSize(12)),
                                    ),
                                    series: <PieSeries<_MonthlyStat, String>>[
                                      PieSeries<_MonthlyStat, String>(
                                        dataSource: nonZeroMonths,
                                        xValueMapper:
                                            (_MonthlyStat stat, _) =>
                                                stat.month,
                                        yValueMapper:
                                            (_MonthlyStat stat, _) => stat.orders,
                                        dataLabelMapper:
                                            (_MonthlyStat stat, _) =>
                                                '${stat.month}: ${stat.orders}',
                                        dataLabelSettings:
                                            const DataLabelSettings(
                                          isVisible: true,
                                          textStyle: TextStyle(
                                            fontSize: 10,
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),


                    SizedBox(height: h(24)),

                    // ─── C) EXTRA CONTENT ────────────────────────────────────
                    const CompactDeliveryDetailsWidget(),
                    SizedBox(height: h(100)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  /// Fetch the authenticated owner’s shop name.
  Future<String> _fetchShopName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final res = await http.get(
      Uri.parse('http://192.168.1.22:8000/api/owner/profile'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['shop_name'] as String;
    } else {
      throw Exception('Failed to load shop name');
    }
  }

  /// Call Laravel endpoint `/api/owner/stats?year=$year` and parse the result.
  Future<List<_MonthlyStat>> _fetchStatsFromApi(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    final url =
        Uri.parse('http://192.168.1.22:8000/api/owner/stats?year=$year');
    final res = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Error fetching stats: ${res.statusCode}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    debugPrint('DEBUG raw stats JSON: ${jsonEncode(data)}');

    final monthsMap = data['monthly'] as Map<String, dynamic>;

    List<_MonthlyStat> list = [];
    for (int m = 1; m <= 12; m++) {
      final monthKey = m.toString();
      if (monthsMap.containsKey(monthKey)) {
        final entry = monthsMap[monthKey] as Map<String, dynamic>;
        final earnings = (entry['earnings'] as num).toDouble();
        final orders = (entry['orders'] as num).toInt();
        list.add(_MonthlyStat(_monthName(m), earnings, orders));
      } else {
        list.add(_MonthlyStat(_monthName(m), 0.0, 0));
      }
    }

    debugPrint('DEBUG parsed monthlyStats list:');
    for (var stat in list) {
      debugPrint('  ${stat.month}: earnings=${stat.earnings}, orders=${stat.orders}');
    }

    return list;
  }

  String _monthName(int m) {
    const names = <String>[
      '', // dummy index 0
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m];
  }
}

class EnlargePieChartPage extends StatelessWidget {
  // ignore: library_private_types_in_public_api
  final List<_MonthlyStat> monthlyStats; // already filtered
  final int year;

  const EnlargePieChartPage({
    super.key,
    required this.monthlyStats,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Monthly Orders ($year)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SfCircularChart(
          margin: EdgeInsets.zero,
          legend: Legend(
            isVisible: true,
            height: '100%',
            overflowMode: LegendItemOverflowMode.wrap,
            position: LegendPosition.bottom,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: '{point.x}: {point.y}',
            textStyle: const TextStyle(fontSize: 14),
          ),
          series: <PieSeries<_MonthlyStat, String>>[
            PieSeries<_MonthlyStat, String>(
              dataSource: monthlyStats,
              xValueMapper: (_MonthlyStat stat, _) => stat.month,
              yValueMapper: (_MonthlyStat stat, _) => stat.orders,
              dataLabelMapper: (_MonthlyStat stat, _) =>
                  '${stat.month}: ${stat.orders}',
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(
                  fontSize: 12,
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
    );
  }
}

class EnlargeBarChartPage extends StatelessWidget {
  // ignore: library_private_types_in_public_api
  final List<_MonthlyStat> monthlyStats;
  final int year;

  const EnlargeBarChartPage({
    super.key,
    required this.monthlyStats,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Monthly Earnings ($year)',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SfCartesianChart(
          margin: EdgeInsets.zero,
          primaryXAxis: CategoryAxis(
            labelStyle: const TextStyle(fontSize: 12),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            labelFormat: '₱{value}',
            interval: 5000, // adjust if needed
            axisLine: const AxisLine(width: 0),
            majorTickLines: const MajorTickLines(size: 0),
            labelStyle: const TextStyle(fontSize: 12),
          ),
          tooltipBehavior: TooltipBehavior(
            enable: true,
            format: 'point.y',
            header: '',
            textStyle: const TextStyle(fontSize: 14),
          ),
          series: <ColumnSeries<_MonthlyStat, String>>[
            ColumnSeries<_MonthlyStat, String>(
              dataSource: monthlyStats,
              xValueMapper: (_MonthlyStat stat, _) => stat.month,
              yValueMapper: (_MonthlyStat stat, _) => stat.earnings,
              color: const Color(0xFF455567),
              width: 0.6,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              // dataLabelSettings: const DataLabelSettings(
              //   isVisible: true,
              //   textStyle: TextStyle(
              //     fontSize: 12,
              //     color: Colors.white12,
              //     fontWeight: FontWeight.w600,
              //   ),
              //   labelAlignment: ChartDataLabelAlignment.top,
              //   labelPosition: ChartDataLabelPosition.outside,
              // ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple data‐model for month, earnings, and orders.
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
    //  ➤ NEW: Controller for “Borrow gallon” price:
  final TextEditingController _borrowGallonPriceController =
      TextEditingController(text: '₱0.00');

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
    _borrowGallonPriceController.dispose();
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
      final url = Uri.parse('http://192.168.1.22:8000/api/owner/shop-details');
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
          //  ➤ NEW: Update borrow gallon price
          final borrowPrice = shopDetails['borrow_price'];
          if (borrowPrice != null) {
            _borrowGallonPriceController.text = '₱${borrowPrice.toString()}';
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
      color: const Color(0xffF1EFEC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: w(15), vertical: h(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Edit details header ───────────────────────────────────────
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

          // ─── Preferred delivery time section ─────────────────────────
          Text(
            'Preferred delivery time',
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
            children: _deliveryTimes.map((time) {
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
                    color: isSelected
                        ? const Color(0xFF5CB338)
                        : const Color(0xFF1F2937),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: isSelected
                          ? const BorderSide(color: Colors.blue, width: 2.0)
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

          // ─── Collection day section ───────────────────────────────────
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

          // Collection day selection – compact row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _collectionDays.map((day) {
              final isSelected = _selectedDays.contains(day);
              return Column(
                children: [
                  Container(
                    width: w(18),
                    height: h(18),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1F2937) : Colors.white,
                      border: Border.all(color: const Color(0xFF1F2937), width: 1.5),
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

          // ─── Borrow gallon row ───────────────────────────────────────
          _buildBorrowPriceRow(screenWidth - w(40)),

          SizedBox(height: h(15)),

          // ─── Regular & Dispenser gallon row ─────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Regular gallon (fixed product)
              _buildGallonItem(
                'images/regular.png',
                _regularGallonPriceController,
                (screenWidth - w(40)) / 2 - w(10),
              ),

              // Dispenser gallon (fixed product)
              _buildGallonItem(
                'images/dispenser.png',
                _dispenserGallonPriceController,
                (screenWidth - w(40)) / 2 - w(10),
              ),
            ],
          ),

          SizedBox(height: h(15)),

          // ─── Save button ─────────────────────────────────────────────
          Center(
            child: ElevatedButton(
              onPressed: _isLoading
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
              child: _isLoading
                  ? SizedBox(
                      width: w(20),
                      height: h(20),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

/// Helper method to build the “Borrow gallon (₱0): [ TextField ]” row
Widget _buildBorrowPriceRow(double totalWidth) {
  const double rowHeight = 36;
  const double horizontalPadding = 16;

  return Container(
    width: totalWidth,
    height: rowHeight,
    decoration: ShapeDecoration(
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      shadows: const [
        BoxShadow(
          color: Color(0x3F000000),
          blurRadius: 4,
          offset: Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Row(
      children: [
        // Left label: "Borrow gallon (₱0):"
        Padding(
          padding: const EdgeInsets.only(left: horizontalPadding),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Borrow gallon (',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: '₱${_borrowGallonPriceController.text}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '):',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Spacer pushes the right-side text field to the end
        const Spacer(),

        // Right-side text field container
        Padding(
          padding: const EdgeInsets.only(right: horizontalPadding),
          child: Container(
            width: 131,
            height: 26,
            decoration: ShapeDecoration(
              color: const Color(0xFFD9D9D9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Center(
              child: TextField(
                controller: _borrowGallonPriceController,
                textAlign: TextAlign.end,
                decoration: const InputDecoration(
                  hintText: 'Type your price here',
                  hintStyle: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    height: 2,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w800,
                  height: 2,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ),
        ),
      ],
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
      width: 150 * widthScaleFactor, // Scale width based on design
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
                color: const Color(0xFF1F2937),
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
                  color: Colors.white,
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
          //  ➤ NEW: parse borrow price
    final borrowPrice = double.tryParse(
          _borrowGallonPriceController.text.replaceAll('₱', '').trim(),
        ) ??
        0.0;

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
        'borrow_price': borrowPrice,
      };

      debugPrint('Sending shop details: $payload');

      // Send to backend
      final url = Uri.parse('http://192.168.1.22:8000/api/owner/shop-details');
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
