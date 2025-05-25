import 'package:flutter/material.dart';

class CustomBottomNavBarRider extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomNavBarRider({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<CustomBottomNavBarRider> createState() => _CustomBottomNavBarRiderState();
}

class _CustomBottomNavBarRiderState extends State<CustomBottomNavBarRider> {
  // Only Maps, Orders, Profile
  final List<IconData> navIcons = [
    Icons.location_pin,     // Map
    Icons.list_alt,         // Orders
    Icons.person,           // Profile
  ];

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double navBarWidth  = _getResponsiveWidth(screenSize.width);
    final double navBarHeight = _getResponsiveHeight(screenSize.height);
    final double iconSize     = _getResponsiveIconSize(screenSize);

    return Container(
      width: navBarWidth,
      height: navBarHeight,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7F8),
        borderRadius: BorderRadius.circular(navBarHeight / 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row( 
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          navIcons.length,
          (index) => _buildNavItem(navIcons[index], index, iconSize),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, double iconSize) {
    final bool isSelected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () => widget.onItemTapped(index),
      child: Opacity(
        opacity: isSelected ? 1.0 : 0.8,
        child: Container(
          width: iconSize * 1.5,
          height: iconSize * 1.5,
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey.shade200 : Colors.transparent,
            borderRadius: BorderRadius.circular(iconSize / 2),
          ),
          child: Icon(
            icon,
            color: isSelected ? const Color(0xff1F2937) : Colors.grey,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  double _getResponsiveWidth(double screenWidth) {
    if (screenWidth < 360) {
      return screenWidth * 0.85;
    } else if (screenWidth < 600) {return screenWidth * 0.82;}
    else if (screenWidth < 768) {return screenWidth * 0.70;}
    else if (screenWidth < 1024) {return screenWidth * 0.60;}
    else {return 500;}
  }

  double _getResponsiveHeight(double screenHeight) {
    if (screenHeight < 700) {
      return 60;
    } else if (screenHeight < 900) {return 67;}
    else if (screenHeight < 1200) {return 75;}
    else {return 85;}
  }

  double _getResponsiveIconSize(Size screenSize) {
    final double smaller = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;

    if (smaller < 360) {
      return 20;
    } else if (smaller < 600) {return 24;}
    else if (smaller < 900) {return 28;}
    else {return 32;}
  }
}
