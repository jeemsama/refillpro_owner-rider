import 'package:geocoding/geocoding.dart';
import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/auth/approval_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  LatLng selectedLocation = LatLng(17.6502, 121.7334); // Default Tuguegarao
  final LatLng allowedCenter = LatLng(17.6607, 121.7525); // Approx: Carig Sur
  final double allowedRadiusKm = 1.0;
  final Distance _distance = const Distance();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool isWithinRadius(LatLng center, LatLng point, double radiusKm) {
    return _distance.as(LengthUnit.Kilometer, center, point) <= radiusKm;
  }

  File? dtiFile;
  File? permitFile;

  File? shopPhoto;
  final ImagePicker picker = ImagePicker();

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

  Future<void> reverseGeocode(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final fullAddress =
            "${place.name}, ${place.street}, ${place.locality}, ${place.administrativeArea}";
        setState(() {
          _addressController.text = fullAddress;
        });
      }
    } catch (e) {
      debugPrint("Reverse geocoding failed: $e");
    }
  }

  Future<void> forwardGeocode(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        LatLng newLocation = LatLng(loc.latitude, loc.longitude);
        setState(() {
          selectedLocation = newLocation;
        });
        mapController.move(newLocation, 16);
      }
    } catch (e) {
      debugPrint("Forward geocoding failed: $e");
    }
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
        mapController.move(selectedLocation, 13);
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

  Future<void> submitOwnerRegistration() async {
    try {
      // 1️⃣ Show loading spinner
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF5F8B4C)),
            ),
      );

      final uri = Uri.parse('http://192.168.1.6:8000/api/v1/register-owner');
      debugPrint('Sending request to: $uri');

      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json';

      void safePop() {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      }

      // 2️⃣ Basic form validation
      if (_nameController.text.isEmpty ||
          _phoneController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _shopNameController.text.isEmpty ||
          _addressController.text.isEmpty) {
        safePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      if (!termsAgreed) {
        safePop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must agree to the terms and conditions.'),
          ),
        );
        return;
      }

      // 3️⃣ Attach text fields
      request.fields
        ..['name'] = _nameController.text.trim()
        ..['phone'] = _phoneController.text.trim()
        ..['email'] = _emailController.text.trim()
        ..['password'] = _passwordController.text
        ..['shop_name'] = _shopNameController.text.trim()
        ..['address'] = _addressController.text.trim()
        ..['latitude'] = selectedLocation.latitude.toStringAsFixed(7)
        ..['longitude'] = selectedLocation.longitude.toStringAsFixed(7)
        ..['agreed_to_terms'] = termsAgreed ? '1' : '0';

      // 4️⃣ Attach files (if any)
      if (dtiFile != null) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath('dti_permit_path', dtiFile!.path),
          );
        } catch (_) {
          /* ignore */
        }
      }
      if (permitFile != null) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath(
              'business_permit_path',
              permitFile!.path,
            ),
          );
        } catch (_) {
          /* ignore */
        }
      }
      if (shopPhoto != null) {
        try {
          request.files.add(
            await http.MultipartFile.fromPath('shop_photo', shopPhoto!.path),
          );
        } catch (_) {
          /* ignore */
        }
      }

      debugPrint('Request fields: ${request.fields}');

      // 5️⃣ Send
      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();

      safePop(); // hide spinner
      debugPrint('Response ${streamed.statusCode}: $responseBody');

      // 6️⃣ Try to decode JSON only if non-empty
      Map<String, dynamic>? responseData;
      if (responseBody.trim().isNotEmpty) {
        try {
          final decoded = json.decode(responseBody);
          if (decoded is Map<String, dynamic>) {
            responseData = decoded;
            debugPrint('Decoded JSON: $responseData');
          }
        } catch (e) {
          debugPrint('Invalid JSON: $e');
        }
      }

      // 7️⃣ Success
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        debugPrint('Registration successful');

        // extract the new owner/shop ID if available
        int? ownerId;
        if (responseData != null &&
            responseData['data'] is Map<String, dynamic> &&
            (responseData['data'] as Map<String, dynamic>)['id'] is int) {
          ownerId = (responseData['data'] as Map<String, dynamic>)['id'] as int;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration submitted for approval!'),
            backgroundColor: Color(0xFF5F8B4C),
          ),
        );

        // ✨ Save only the ownerId
        final prefs = await SharedPreferences.getInstance();
        if (ownerId != null) {
          await prefs.setInt('owner_id', ownerId);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ApprovalScreen()),
        );
        return;
      }

      // 8️⃣ Error path
      String errorMessage = 'Registration failed';
      if (responseData != null) {
        errorMessage =
            responseData['message'] ?? responseData['error'] ?? errorMessage;
      } else if (streamed.statusCode == 422) {
        errorMessage = 'Invalid or missing data. Please check all fields.';
      } else if (streamed.statusCode >= 500) {
        errorMessage =
            'Server error (${streamed.statusCode}), try again later.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e, st) {
      debugPrint('Exception: $e\n$st');
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                              onSubmitted: (value) {
                                forwardGeocode(value);
                              },
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
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: selectedLocation,
                              initialZoom: 13,
                              onTap: (tapPosition, latLng) {
                                if (isWithinRadius(
                                  allowedCenter,
                                  latLng,
                                  allowedRadiusKm,
                                )) {
                                  setState(() {
                                    selectedLocation = latLng;
                                  });
                                  reverseGeocode(latLng);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please select a location within 10km of Carig Sur, Tuguegarao City.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              interactionOptions: const InteractionOptions(
                                flags:
                                    InteractiveFlag.pinchZoom |
                                    InteractiveFlag.drag, // disables long-press
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.refillproo',
                              ),
                              // CircleLayer(
                              //   circles: [
                              //     CircleMarker(
                              //       point: allowedCenter,
                              //       // ignore: deprecated_member_use
                              //       color: Colors.blue.withOpacity(0.2),
                              //       borderStrokeWidth: 2,
                              //       borderColor: Colors.blue,
                              //       useRadiusInMeter: true,
                              //       radius: 1000, // meters = 3km
                              //     ),
                              //   ],
                              // ),
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
