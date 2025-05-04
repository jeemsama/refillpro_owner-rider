import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Store the previous status bar style to restore it later

  @override
  void initState() {
    super.initState();
    
    // Store the current style before changing it
// Default fallback
    
    // Set the Profile-specific style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1F2937),
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    // IMPORTANT: Reset to the default app style when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Default transparent
      statusBarIconBrightness: Brightness.dark, // Default dark icons
    ));
    super.dispose();
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
        ),
      ),
      body: const ProfileContent(),
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

                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
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
                  ),

                  const SizedBox(height: 50),

                  AddRiderWidget(),

                  const SizedBox(height: 50),
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









class AddRiderWidget extends StatefulWidget {
  const AddRiderWidget({super.key});

  @override
  State<AddRiderWidget> createState() => _AddRiderWidgetState();
}

class _AddRiderWidgetState extends State<AddRiderWidget> {
  // Text controllers for input fields
  final TextEditingController nameController = TextEditingController(text: 'AquaLife');
  final TextEditingController emailController = TextEditingController(text: 'sampleemail@gmail.com');
  final TextEditingController contactNumberController = TextEditingController(text: '09275313243');
  final TextEditingController passwordController = TextEditingController(text: '**************');

  // Focus nodes for input fields
  final FocusNode nameFocus = FocusNode();
  final FocusNode emailFocus = FocusNode();
  final FocusNode contactNumberFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  
  bool obscurePassword = true;

  @override
  void dispose() {
    // Dispose controllers when widget is removed
    nameController.dispose();
    emailController.dispose();
    contactNumberController.dispose();
    passwordController.dispose();
    
    // Dispose focus nodes
    nameFocus.dispose();
    emailFocus.dispose();
    contactNumberFocus.dispose();
    passwordFocus.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive scaling
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final widthScaleFactor = screenWidth / 401;

    double w(double value) => value * widthScaleFactor;
    double h(double value) => value * widthScaleFactor;
    double fontSize(double value) => value * widthScaleFactor;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w(16)),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFEC),
        borderRadius: BorderRadius.circular(w(15)),
        // boxShadow: [
        //   BoxShadow(
        //     color: const Color.fromRGBO(0, 0, 0, 0.1),
        //     blurRadius: w(4),
        //     offset: Offset(0, h(2)),
        //   ),
        // ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Add rider',
            style: TextStyle(
              color: const Color(0xFF1F2937),
              fontSize: fontSize(24),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: h(25)),
          
          // Form fields
          _buildInputField(
            label: 'name',
            controller: nameController,
            focusNode: nameFocus,
            nextFocusNode: emailFocus,
            w: w,
            h: h,
            fontSize: fontSize,
          ),
          SizedBox(height: h(15)),
          
          _buildInputField(
            label: 'email',
            controller: emailController,
            focusNode: emailFocus,
            nextFocusNode: contactNumberFocus,
            keyboardType: TextInputType.emailAddress,
            w: w,
            h: h,
            fontSize: fontSize,
          ),
          SizedBox(height: h(15)),
          
          _buildInputField(
            label: 'Contact Number',
            controller: contactNumberController,
            focusNode: contactNumberFocus,
            nextFocusNode: passwordFocus,
            keyboardType: TextInputType.phone,
            w: w,
            h: h,
            fontSize: fontSize,
          ),
          SizedBox(height: h(15)),
          
          _buildPasswordField(
            label: 'password',
            controller: passwordController,
            focusNode: passwordFocus,
            w: w,
            h: h,
            fontSize: fontSize,
          ),
          
          SizedBox(height: h(20)),
          
          // Button
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () {
                // Handle add rider functionality here
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rider added successfully!')),
                );
              },
              child: Container(
                width: w(96),
                height: h(36),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(w(10)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x3F000000),
                      blurRadius: w(4),
                      offset: Offset(0, h(4)),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize(15),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    TextInputType keyboardType = TextInputType.text,
    required double Function(double) w,
    required double Function(double) h,
    required double Function(double) fontSize,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w(10)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize(12),
                      color: Colors.grey.shade600,
                    ),
                  ),
          TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize(16),
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 1),
              border: InputBorder.none,
            ),
            onSubmitted: (_) {
              if (nextFocusNode != null) {
                FocusScope.of(context).requestFocus(nextFocusNode);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required double Function(double) w,
    required double Function(double) h,
    required double Function(double) fontSize,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w(16), vertical: h(10)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: fontSize(9),
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w300,
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscurePassword,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: fontSize(12),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    obscurePassword = !obscurePassword;
                  });
                },
                child: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off,
                  size: fontSize(16),
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}