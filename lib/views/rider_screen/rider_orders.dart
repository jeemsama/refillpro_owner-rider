import 'package:flutter/material.dart';

/// Only title + 2-item TabBar in Rider app
class RiderOrders extends StatelessWidget {
  const RiderOrders({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // <-- exactly two tabs
      child: Column(
        children: [
          // Top title + TabBar
          PreferredSize(
            preferredSize: const Size.fromHeight(77),
            child: Container(
              color: const Color(0xFFF2F2F2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Row(
                      children: [
                        const Text(
                          'Deliveries today',
                          style: TextStyle(
                            fontFamily: 'PoppinsExtraBold',
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        const Spacer(),
                        // TabBar with exactly two tabs:
                        const TabBar(
                          isScrollable: true,
                          dividerColor: Colors.transparent,
                          indicatorColor: Colors.black,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          labelPadding:
                              EdgeInsets.symmetric(horizontal: 12),
                          tabs: [
                            Tab(text: 'Pending'),
                            Tab(text: 'Redeliver'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // The two tab views:
          Expanded(
            child: const TabBarView(
              children: [
                Center(child: Text('No pending deliveries yet.')),
                Center(child: Text('No redeliveries pending.')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
