// lib/views/owner_screen/orders.dart

import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/bottom_navbar.dart';
import 'package:refillpro_owner_rider/views/header.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/owner_screen/maps.dart';
import 'package:refillpro_owner_rider/views/owner_screen/profile.dart';

class Orders extends StatefulWidget {
  const Orders({super.key});

  @override
  State<Orders> createState() => _OrdersState();
}

class _OrdersState extends State<Orders> {
  int _selectedIndex = 2;

  // Four main screens: Home, Map, Orders, Profile
  final List<Widget> _screens = const [
    HomeContent(),
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
          // — Header at top (outside SafeArea)
          const Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: AppHeader(),
          ),
          // — Main content + navbar inside SafeArea
          Positioned(
            top: 83, // header height
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Stack(
                children: [
                  // Selected screen area
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    bottom: 97, // navbar + margin
                    child: _screens[_selectedIndex],
                  ),
                  // Bottom navigation bar
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

/// This is the “Orders” tab content: title + tabs only.
class OrdersContent extends StatefulWidget {
  const OrdersContent({super.key});

  @override
  State<OrdersContent> createState() => _OrdersContentState();
}

class _OrdersContentState extends State<OrdersContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title + TabBar
        PreferredSize(
          preferredSize: const Size.fromHeight(77),
          child: Container(
            color: const Color(0xFFF1EFEC),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontFamily: 'PoppinsExtraBold',
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const Spacer(),
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: Colors.black,
                        dividerColor: Colors.transparent,
                        labelColor: Colors.black,
                        unselectedLabelColor: Colors.grey,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        tabs: const [
                          Tab(text: 'Pending'),
                          Tab(text: 'Completed'),
                          Tab(text: 'Cancelled'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tab content placeholders
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              Center(child: Text('Pending orders')),
              Center(child: Text('Completed orders')),
              Center(child: Text('Cancelled orders')),
            ],
          ),
        ),
      ],
    );
  }
}
