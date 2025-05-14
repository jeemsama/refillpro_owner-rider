import 'dart:math';

import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/auth/approval_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  LatLng selectedLocation = LatLng(17.6131, 121.7269); // Default Tuguegarao

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  File? dtiFile;
  File? permitFile;

  File? shopPhoto;
  final ImagePicker picker = ImagePicker();

  // Map<String, bool> selectedGallons = {
  //   'has_regular_gallon': false,
  //   'has_dispenser_gallon': false,
  //   'has_small_gallon': false,
  // };

  // final TextEditingController regularPriceController = TextEditingController(text: "₱30.00");
  // final TextEditingController dispenserPriceController = TextEditingController(text: "₱30.00");
  // final TextEditingController smallPriceController = TextEditingController(text: "₱25.00");

  // Map<String, bool> morningSlots = {
  //   "7am": false,
  //   "8am": false,
  //   "9am": false,
  //   "10am": false,
  //   "11am": false,
  // };

  Map<String, bool> afternoonSlots = {
    "12pm": false,
    "1pm": false,
    "2pm": false,
    "3pm": false,
    "4pm": false,
  };

  bool termsAgreed = false;

  final MapController mapController = MapController();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          selectedLocation = LatLng(position.latitude, position.longitude);
        });
        mapController.move(selectedLocation, 16.0);
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    // regularPriceController.dispose();
    // dispenserPriceController.dispose();
    // smallPriceController.dispose();
    super.dispose();
  }

  Future<void> pickDTIFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        dtiFile = File(result.files.single.path!);
      });
      debugPrint('DTI file selected: ${dtiFile!.path}');
    }
  }

  Future<void> pickPermitFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        permitFile = File(result.files.single.path!);
      });
      debugPrint('Permit file selected: ${permitFile!.path}');
    }
  }

  Future<void> choosePhotoFromGallery() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        shopPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> takePhotoWithCamera() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        shopPhoto = File(pickedFile.path);
      });
    }
  }

  // testing

  bool validateForm() {
    if (_nameController.text.isEmpty) {
      showErrorSnackBar('Please enter your name');
      return false;
    }

    if (_phoneController.text.isEmpty) {
      showErrorSnackBar('Please enter your phone number');
      return false;
    }

    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      showErrorSnackBar('Please enter a valid email address');
      return false;
    }

    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      showErrorSnackBar('Password must be at least 6 characters');
      return false;
    }

    if (_shopNameController.text.isEmpty) {
      showErrorSnackBar('Please enter your shop name');
      return false;
    }

    if (_addressController.text.isEmpty) {
      showErrorSnackBar('Please enter your address');
      return false;
    }

    // if (!selectedGallons.values.contains(true)) {
    //   showErrorSnackBar('Please select at least one gallon type');
    //   return false;
    // }

    // List<String> selectedSlots = [
    //   ...morningSlots.entries.where((e) => e.value).map((e) => e.key),
    //   ...afternoonSlots.entries.where((e) => e.value).map((e) => e.key),
    // ];

    // if (selectedSlots.isEmpty) {
    //   showErrorSnackBar('Please select at least one delivery time slot');
    //   return false;
    // }

    if (!termsAgreed) {
      showErrorSnackBar('You must agree to the terms and conditions');
      return false;
    }

    return true;
  }

  void showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // This function properly formats and returns the selected time slots as an array
  // List<String> getSelectedTimeSlots() {
  //   List<String> selectedSlots = [];

  // Add morning slots that are selected (true)
  // morningSlots.forEach((time, isSelected) {
  //   if (isSelected) {
  //     selectedSlots.add(time);
  //   }
  // });

  // Add afternoon slots that are selected (true)
  //   afternoonSlots.forEach((time, isSelected) {
  //     if (isSelected) {
  //       selectedSlots.add(time);
  //     }
  //   });

  //   return selectedSlots;
  // }

  Future<void> submitOwnerRegistration() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F8B4C)),
            ),
      );

      // Prepare the API URL
      // If testing on an emulator, consider using 10.0.2.2 instead of the IP
      final uri = Uri.parse('http://192.168.1.43:8000/api/v1/register-owner');
      debugPrint('Sending request to: $uri');

      var request = http.MultipartRequest('POST', uri);

      // Add required authentication headers if needed
      // request.headers['Authorization'] = 'Bearer YOUR_TOKEN';
      request.headers['Accept'] = 'application/json';

      void safePop() {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }

      // Validate required fields
      if (_nameController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _shopNameController.text.isEmpty ||
          _addressController.text.isEmpty) {
        safePop(); // Dismiss loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      // Get selected time slots
      // List<String> selectedSlots = getSelectedTimeSlots();

      // Check if at least one gallon type is selected
      // if (!selectedGallons.values.contains(true)) {
      //   safePop(); // Dismiss loading indicator
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Please select at least one gallon type')),
      //   );
      //   return;
      // }

      // Format and add form fields
      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['email'] = _emailController.text.trim();
      request.fields['password'] = _passwordController.text;
      request.fields['shop_name'] = _shopNameController.text.trim();
      request.fields['address'] = _addressController.text.trim();
      request.fields['latitude'] = selectedLocation.latitude.toStringAsFixed(7);
      request.fields['longitude'] = selectedLocation.longitude.toStringAsFixed(
        7,
      );
      request.fields['agreed_to_terms'] = termsAgreed ? '1' : '0';

      // // Utility to sanitize price input
      // String sanitizePrice(String input) {
      //   final numeric = RegExp(r'[\d.]+');
      //   final match = numeric.allMatches(input.replaceAll(RegExp(r'[₱,\s]'), ''));
      //   return match.isNotEmpty ? match.first.group(0) ?? '0' : '0';
      // }

      // // Utility to check if price is zero and show message
      // bool isZeroPrice(String price, String label, BuildContext context) {
      //   if (price == '0' || price == '0.0' || price == '0.00') {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       SnackBar(content: Text('Please enter a valid price for $label')),
      //     );
      //     return true;
      //   }
      //   return false;
      // }

      // Process gallon types with proper price formatting
      //   bool hasZeroPrice = false;

      //   if (selectedGallons['has_regular_gallon'] == true) {
      //     String price = sanitizePrice(regularPriceController.text);
      //     if (isZeroPrice(price, "Regular Gallon", context)) hasZeroPrice = true;
      //     request.fields['has_regular_gallon'] = '1';
      //     request.fields['regular_gallon_price'] = price;
      //     debugPrint('Regular price: $price');
      //   } else {
      //     request.fields['has_regular_gallon'] = '0';
      //   }

      //   if (selectedGallons['has_dispenser_gallon'] == true) {
      //     String price = sanitizePrice(dispenserPriceController.text);
      //     if (isZeroPrice(price, "Dispenser Gallon", context)) hasZeroPrice = true;
      //     request.fields['has_dispenser_gallon'] = '1';
      //     request.fields['dispenser_gallon_price'] = price;
      //     debugPrint('Dispenser price: $price');
      //   } else {
      //     request.fields['has_dispenser_gallon'] = '0';
      //   }

      //   if (selectedGallons['has_small_gallon'] == true) {
      //     String price = sanitizePrice(smallPriceController.text);
      //     if (isZeroPrice(price, "Small Gallon", context)) hasZeroPrice = true;
      //     request.fields['has_small_gallon'] = '1';
      //     request.fields['small_gallon_price'] = price;
      //     debugPrint('Small price: $price');
      //   } else {
      //     request.fields['has_small_gallon'] = '0';
      //   }

      //   // Stop request if any zero price was detected
      //   if (hasZeroPrice) return;

      //       // Check if at least one time slot is selected
      //   if (selectedSlots.isEmpty) {
      //     safePop(); // Dismiss loading indicator
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Please select at least one delivery time slot')),
      //     );
      //     return;
      //   }

      // // Send as array items
      // for (int i = 0; i < selectedSlots.length; i++) {
      //   request.fields['delivery_time_slots[$i]'] = selectedSlots[i];
      // }

      //check for terms and coditions
      if (!termsAgreed) {
        safePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must agree to the terms and conditions.'),
          ),
        );
        return;
      }

      // Add files if selected
      if (dtiFile != null) {
        debugPrint('Adding DTI file: ${dtiFile!.path}');
        try {
          request.files.add(
            await http.MultipartFile.fromPath('dti_permit_path', dtiFile!.path),
          );
        } catch (e) {
          debugPrint('Error adding DTI file: $e');
          // Continue with submission even if file attachment fails
        }
      } else {
        debugPrint('Warning: No DTI file selected');
      }

      if (permitFile != null) {
        debugPrint('Adding permit file: ${permitFile!.path}');
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'business_permit_path',
              permitFile!.path,
            ),
          );
        } catch (e) {
          debugPrint('Error adding permit file: $e');
          // Continue with submission even if file attachment fails
        }
      } else {
        debugPrint('Warning: No permit file selected');
      }

      if (shopPhoto != null) {
        debugPrint('Adding shop photo: ${shopPhoto!.path}');
        try {
          request.files.add(
            await http.MultipartFile.fromPath('shop_photo', shopPhoto!.path),
          );
        } catch (e) {
          debugPrint('Warning: No shop photo selected');
        }
      }

      // Log the complete request for debugging
      debugPrint('Request fields: ${request.fields}');

      // Try multiple status codes for success
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();

      safePop(); // Dismiss loading indicator

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: $responseBody');

      // Parse response if it's JSON
      Map<String, dynamic>? responseData;
      try {
        responseData = json.decode(responseBody);
        debugPrint('Parsed response: $responseData');
      } catch (e) {
        debugPrint('Not a valid JSON response');
      }

      // Check for success - accept either 200 or 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Registration successful');

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Awaiting approval.'),
            backgroundColor: Color(0xFF5F8B4C),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ApprovalScreen()),
        );
      } else {
        // Handle specific error codes
        String errorMessage = 'Registration failed';

        if (responseData != null && responseData.containsKey('message')) {
          errorMessage = '${responseData['message']}';
        } else if (responseData != null && responseData.containsKey('error')) {
          errorMessage = '${responseData['error']}';
        } else if (response.statusCode == 422) {
          errorMessage = 'Invalid or missing data. Please check all fields.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Authentication error';
        } else if (response.statusCode == 403) {
          errorMessage = 'Permission denied';
        } else if (response.statusCode == 404) {
          errorMessage = 'API endpoint not found';
        } else if (response.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        }

        debugPrint('Error: $errorMessage');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception: $e');
      debugPrint('StackTrace: $stackTrace');

      if (!mounted) return;

      // Dismiss loading indicator if it's showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().substring(0, min(e.toString().length, 100))}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // // Helper method to build time slot checkbox
  // Widget _buildTimeSlotCheckbox(String time, Map<String, bool> slots) {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       SizedBox(
  //         width: 24,
  //         height: 24,
  //         child: Checkbox(
  //           value: slots[time],
  //           onChanged: (value) {
  //             setState(() {
  //               slots[time] = value ?? false;
  //             });
  //           },
  //           fillColor: WidgetStateProperty.resolveWith(
  //             (states) => states.contains(WidgetState.selected)
  //                 ? const Color(0xFF5F8B4C)
  //                 : const Color(0xFFD9D9D9),
  //           ),
  //         ),
  //       ),
  //       const SizedBox(width: 4),
  //       Text(
  //         time,
  //         style: const TextStyle(
  //           color: Color(0xFFE5E7EB),
  //           fontSize: 11,
  //           fontFamily: 'Roboto',
  //           fontWeight: FontWeight.w500,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  // // Helper method to build gallon option with blue border for selected items
  // Widget _buildGallonOption(
  //   String label,
  //   String imagePath,
  //   TextEditingController controller,
  //   String gallonType,
  //   Size screenSize,
  // ) {
  //   final isSelected = selectedGallons[gallonType] ?? false;
  //   final isSmallScreen = screenSize.width < 400;

  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         // Toggle selection instead of replacing
  //         selectedGallons[gallonType] = !(selectedGallons[gallonType] ?? false);
  //       });
  //     },
  //     child: Container(
  //       width: screenSize.width * 0.25,
  //       height: screenSize.height * 0.15,
  //       decoration: BoxDecoration(
  //         color: const Color(0xFF1F2937), // Always dark background
  //         borderRadius: BorderRadius.circular(15),
  //         border: isSelected
  //             ? Border.all(color: Colors.blue, width: 3.0) // Blue stroke for selected items
  //             : null, // No border for unselected items
  //       ),
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           // Actual image container
  //           Container(
  //             width: screenSize.width * 0.15,
  //             height: screenSize.height * 0.08,
  //             decoration: BoxDecoration(
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             child: ClipRRect(
  //               borderRadius: BorderRadius.circular(10),
  //               child: Image.asset(
  //                 imagePath,
  //                 fit: BoxFit.contain,
  //               ),
  //             ),
  //           ),
  //           SizedBox(height: screenSize.height * 0.01),

  //           // Price input field
  //           Container(
  //             width: screenSize.width * 0.15,
  //             height: screenSize.height * 0.03,
  //             decoration: BoxDecoration(
  //               color: const Color(0xFFD9D9D9),
  //               borderRadius: BorderRadius.circular(5),
  //             ),
  //             child: TextField(
  //               controller: controller,
  //               textAlign: TextAlign.center,
  //               style: TextStyle(
  //                 color: Colors.black,
  //                 fontSize: isSmallScreen ? 8 : 10,
  //                 fontFamily: 'Roboto',
  //                 fontWeight: FontWeight.w500,
  //               ),
  //               decoration: InputDecoration(
  //                 border: InputBorder.none,
  //                 contentPadding: EdgeInsets.zero,
  //                 hintText: 'your price',
  //                 hintStyle: TextStyle(
  //                   color: Colors.black54,
  //                   fontSize: isSmallScreen ? 8 : 10,
  //                 ),
  //               ),
  //             ),
  //           ),
  //           SizedBox(height: screenSize.height * 0.01),

  //           // Label
  //           Text(
  //             label,
  //             textAlign: TextAlign.center,
  //             style: TextStyle(
  //               color: const Color(0xFFE5E7EB),
  //               fontSize: isSmallScreen ? 8 : 10,
  //               fontFamily: 'Roboto',
  //               fontWeight: FontWeight.w500,
  //               height: 1.2,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Scale factors based on original design size
    final widthScale = screenWidth / 402;
    final heightScale = screenHeight / 874;
    final isSmallScreen = screenWidth < 400;

    return Scaffold(
      backgroundColor: const Color(0xFF455567),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            width: screenWidth,
            padding: EdgeInsets.symmetric(
              horizontal: 20 * widthScale,
              vertical: 20 * heightScale,
            ),
            child: Column(
              children: [
                SizedBox(height: 40 * heightScale),

                // Basic Verification Section
                Container(
                  width: 362 * widthScale,
                  padding: EdgeInsets.all(16 * widthScale),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF455567),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(
                        width: 1,
                        color: Color(0xFF1F2937),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Basic Verification',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10 * heightScale),
                      const Text(
                        'Please enter complete details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.67,
                        ),
                      ),
                      SizedBox(height: 20 * heightScale),

                      // Name input
                      Row(
                        children: [
                          const SizedBox(
                            width: 72,
                            child: Text(
                              'Name:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * widthScale),
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15 * heightScale),

                      // Phone input
                      Row(
                        children: [
                          const SizedBox(
                            width: 72,
                            child: Text(
                              'Phone:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * widthScale),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15 * heightScale),

                      // Email input
                      Row(
                        children: [
                          const SizedBox(
                            width: 72,
                            child: Text(
                              'Email:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * widthScale),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15 * heightScale),

                      // Password input
                      Row(
                        children: [
                          const SizedBox(
                            width: 84,
                            child: Text(
                              'Password:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * widthScale),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20 * heightScale),

                      // File upload section
                      const Text(
                        'Please upload Business permit and DTI Certificate',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.54,
                        ),
                      ),
                      SizedBox(height: 15 * heightScale),

                      // Choose file buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: pickDTIFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBDC4D4),
                                  minimumSize: Size(
                                    84 * widthScale,
                                    18 * heightScale,
                                  ),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  'Choose File',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF222222),
                                    fontSize: 10,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4 * heightScale),
                              const Text(
                                'DTI Permit',
                                style: TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 10,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: pickPermitFile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBDC4D4),
                                  minimumSize: Size(
                                    84 * widthScale,
                                    18 * heightScale,
                                  ),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  'Choose File',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF222222),
                                    fontSize: 10,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4 * heightScale),
                              const Text(
                                'Business Permit',
                                style: TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 10,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 20 * heightScale),
                      const Divider(color: Color(0xFF1F2937), thickness: 1),
                      SizedBox(height: 20 * heightScale),

                      // Shop Info Section
                      const Text(
                        'Shop Info',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 10 * heightScale),
                      const Text(
                        'Please provide details. This will show on the map.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.67,
                        ),
                      ),
                      SizedBox(height: 20 * heightScale),

                      // Shop name input
                      Row(
                        children: [
                          const SizedBox(
                            width: 91,
                            child: Text(
                              'Shop name:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * widthScale),
                          Expanded(
                            child: TextField(
                              controller: _shopNameController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15 * heightScale),

                      // Address input
                      Row(
                        children: [
                          const SizedBox(
                            width: 91,
                            child: Text(
                              'Address:',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontSize: 16,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                            ),
                          ),
                          SizedBox(width: 10 * widthScale),
                          Expanded(
                            child: TextField(
                              controller: _addressController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 15 * heightScale),

                      // picture of shop overview
                      const Text(
                        'Upload a photo or take a photo in front of your refilling station.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.54,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: choosePhotoFromGallery,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBDC4D4),
                                  minimumSize: Size(
                                    84 * widthScale,
                                    18 * heightScale,
                                  ),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  'Choose a photo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF222222),
                                    fontSize: 10,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // if (shopPhoto != null)
                              //   Padding(
                              //     padding: const EdgeInsets.only(top: 10),
                              //     child: Image.file(
                              //       shopPhoto!,
                              //       width: 200,
                              //       height: 200,
                              //       fit: BoxFit.cover,
                              //     ),
                              //   ),
                              SizedBox(height: 4 * heightScale),
                            ],
                          ),
                          Column(
                            children: [
                              ElevatedButton(
                                onPressed: takePhotoWithCamera,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFBDC4D4),
                                  minimumSize: Size(
                                    84 * widthScale,
                                    18 * heightScale,
                                  ),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  'Take a photo',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF222222),
                                    fontSize: 10,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // if (shopPhoto != null)
                              //   Padding(
                              //     padding: const EdgeInsets.only(top: 10),
                              //     child: Image.file(
                              //       shopPhoto!,
                              //       width: 200,
                              //       height: 200,
                              //       fit: BoxFit.cover,
                              //     ),
                              //   ),
                              SizedBox(height: 4 * heightScale),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 15 * heightScale),

                      // Pin location
                      const Text(
                        'pin your shop location',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontSize: 13,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.54,
                        ),
                      ),
                      SizedBox(height: 10 * heightScale),

                      // Map placeholder
                      Container(
                        width: 307 * widthScale,
                        height: 200 * heightScale,
                        decoration: ShapeDecoration(
                          color: const Color(0xFF1F2937),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: FlutterMap(
                            mapController:
                                mapController, // Add the controller here
                            options: MapOptions(
                              initialCenter: selectedLocation,
                              initialZoom: 15,
                              onTap: (tapPosition, latLng) {
                                setState(() {
                                  selectedLocation = latLng;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.refillproo',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 40,
                                    height: 40,
                                    point: selectedLocation,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20 * heightScale),

                // // Gallons and Delivery Section
                // Container(
                //   width: 362 * widthScale,
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF455567),
                //     borderRadius: BorderRadius.circular(16),
                //     border: Border.all(
                //       width: 1,
                //       color: const Color(0xFF1F2937),
                //     ),
                //   ),
                //   child: Padding(
                //     padding: EdgeInsets.all(16 * widthScale),
                //     child: Column(
                //       children: [
                //         // Title
                //         Text(
                //           'Gallons and Delivery',
                //           textAlign: TextAlign.center,
                //           style: TextStyle(
                //             color: Colors.white,
                //             fontSize: isSmallScreen ? 20 : 24,
                //             fontFamily: 'Poppins',
                //             fontWeight: FontWeight.w800,
                //           ),
                //         ),
                //         SizedBox(height: 10 * heightScale),

                //         // Instruction text
                //         Text(
                //           'Tap your available gallons and type your price.',
                //           textAlign: TextAlign.center,
                //           style: TextStyle(
                //             color: const Color(0xFFE5E7EB),
                //             fontSize: isSmallScreen ? 10 : 12,
                //             fontFamily: 'Roboto',
                //             fontWeight: FontWeight.w500,
                //             height: 1.67,
                //           ),
                //         ),
                //         SizedBox(height: 20 * heightScale),

                //         // Gallon options row
                //         Row(
                //           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //           children: [
                //             // Regular Gallon
                //             _buildGallonOption(
                //               'Regular Gallon',
                //               'images/regular.png',
                //               regularPriceController,
                //               'has_regular_gallon',
                //               screenSize,
                //             ),

                //             // Dispenser Gallon
                //             _buildGallonOption(
                //               'Dispenser Gallon',
                //               'images/dispenser.png',
                //               dispenserPriceController,
                //               'has_dispenser_gallon',
                //               screenSize,
                //             ),

                //             // Small Gallon
                //             _buildGallonOption(
                //               'Small Gallon',
                //               'images/small.png',
                //               smallPriceController,
                //               'has_small_gallon',
                //               screenSize,
                //             ),
                //           ],
                //         ),
                //         SizedBox(height: 30 * heightScale),

                //         // Delivery time slots instruction
                //         Text(
                //           'Select delivery time slots. This will appear in the customer.',
                //           textAlign: TextAlign.center,
                //           style: TextStyle(
                //             color: const Color(0xFFE5E7EB),
                //             fontSize: isSmallScreen ? 10 : 12,
                //             fontFamily: 'Roboto',
                //             fontWeight: FontWeight.w500,
                //             height: 1.67,
                //           ),
                //         ),
                //         SizedBox(height: 20 * heightScale),

                //         // Morning time slots
                //         Row(
                //           children: [
                //             SizedBox(
                //               width: screenWidth * 0.1,
                //               child: Text(
                //                 'Morning:',
                //                 style: TextStyle(
                //                   color: const Color(0xFFE5E7EB),
                //                   fontSize: isSmallScreen ? 14 : 10,
                //                   fontFamily: 'Roboto',
                //                   fontWeight: FontWeight.w500,
                //                   height: 1.25,
                //                 ),
                //               ),
                //             ),
                //             Expanded(
                //               child: Wrap(
                //                 spacing: 8,
                //                 runSpacing: 8,
                //                 children: morningSlots.keys.map((time) {
                //                   return _buildTimeSlotCheckbox(time, morningSlots);
                //                 }).toList(),
                //               ),
                //             ),
                //           ],
                //         ),
                //         SizedBox(height: 20 * heightScale),

                //         // Afternoon time slots
                //         Row(
                //           children: [
                //             SizedBox(
                //               width: screenWidth * 0.1,
                //               child: Text(
                //                 'Afternoon:',
                //                 style: TextStyle(
                //                   color: const Color(0xFFE5E7EB),
                //                   fontSize: isSmallScreen ? 14 : 9,
                //                   fontFamily: 'Roboto',
                //                   fontWeight: FontWeight.w500,
                //                   height: 1.25,
                //                 ),
                //               ),
                //             ),
                //             Expanded(
                //               child: Wrap(
                //                 spacing: 8,
                //                 runSpacing: 8,
                //                 children: afternoonSlots.keys.map((time) {
                //                   return _buildTimeSlotCheckbox(time, afternoonSlots);
                //                 }).toList(),
                //               ),
                //             ),
                //           ],
                //         ),
                //       ],
                //     ),
                //   ),
                // ),
                SizedBox(height: 20 * heightScale),

                // Terms and Conditions Section
                Container(
                  width: 362 * widthScale,
                  decoration: BoxDecoration(
                    color: const Color(0xFF455567),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      width: 1,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16 * widthScale),
                    child: Column(
                      children: [
                        // Title
                        Text(
                          'Terms and Conditions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 20 : 24,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 20 * heightScale),

                        // Scrollable terms text
                        Container(
                          height: 150 * heightScale,
                          decoration: BoxDecoration(
                            color: const Color(0xFF455567).withAlpha(128),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'By registering as a Refilling Station Owner or Delivery Rider on the RefillPro platform, you agree to abide by the following terms and conditions. You certify that all information provided, including personal details, business documents (DTI Certificate and Business Permit), and service preferences, are accurate and truthful. You acknowledge that submission of your registration does not guarantee immediate approval, and all applications are subject to verification by RefillPro administrators. Approved owners are solely responsible for managing their station profile, including the registration and oversight of their assigned delivery riders. Any misuse, fraudulent activity, or breach of platform policies may result in account suspension or permanent removal from the platform. By proceeding, you also consent to the storage and processing of your data in accordance with RefillPro\'s privacy policy.',
                                style: TextStyle(
                                  color: const Color(0xFFE5E7EB),
                                  fontSize: isSmallScreen ? 9 : 10,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20 * heightScale),

                        // Agreement checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: termsAgreed,
                              onChanged: (value) {
                                setState(() {
                                  termsAgreed = value ?? false;
                                });
                              },
                              fillColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                        ? const Color(0xFF5F8B4C)
                                        : const Color(0xFFD9D9D9),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the terms and conditions',
                                style: TextStyle(
                                  color: const Color(0xFFE5E7EB),
                                  fontSize: isSmallScreen ? 9 : 10,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 2,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 20 * heightScale),

                        // Submit button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (validateForm()) {
                                await submitOwnerRegistration();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1A2B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                                vertical: screenSize.height * 0.01,
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
