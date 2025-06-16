import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refillpro_owner_rider/views/owner_screen/add_rider.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:refillpro_owner_rider/views/auth/login.dart'; // ← import your login page
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';





const _apiBase = 'http://192.168.1.36:8000';  // ← your `php artisan serve` host:port


class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  // Animation controller for the settings drawer
  late AnimationController _drawerController;
  late Animation<Offset> _drawerAnimation;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    
    // Set the Profile-specific style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF1F2937),
      statusBarIconBrightness: Brightness.light,
    ));

    // Initialize drawer animation controller
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _drawerAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),  // Start from right side (off screen)
      end: Offset.zero,               // End at visible position
    ).animate(CurvedAnimation(
      parent: _drawerController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // IMPORTANT: Reset to the default app style when leaving this screen
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Default transparent
      statusBarIconBrightness: Brightness.dark, // Default dark icons
    ));
    _drawerController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    if (_isDrawerOpen) {
      _drawerController.reverse();
    } else {
      _drawerController.forward();
    }
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _handleRidersTap() {
    // Handle Riders menu item tap
    _toggleDrawer(); // Close drawer
    // Navigate to Riders page
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AddRider()));
  }

  void _handleLogoutTap() {
    _toggleDrawer();
    _confirmLogout();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout ?? false) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('shop_name');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (_) => false,
      );
    }
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
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: _toggleDrawer, // Toggle the settings drawer
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main profile content
          ProfileContent(),
          
          // Overlay when drawer is open
          if (_isDrawerOpen || _drawerController.status == AnimationStatus.forward || 
              _drawerController.status == AnimationStatus.reverse)
            Positioned.fill(
              child: GestureDetector(
                onTap: _isDrawerOpen ? _toggleDrawer : null,
                child: Container(
                  color: _isDrawerOpen ? const Color.fromRGBO(0, 0, 0, 0.4) : Colors.transparent,
                ),
              ),
            ),
          
          // Animated Settings Drawer
          SlideTransition(
            position: _drawerAnimation,
            child: Align(
              alignment: Alignment.centerRight,
              child: SettingsDrawer(
                onRidersTap: _handleRidersTap,
                onLogoutTap: _handleLogoutTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Drawer Widget
class SettingsDrawer extends StatelessWidget {
  final Function() onRidersTap;
  final Function() onLogoutTap;

  const SettingsDrawer({
    super.key,
    required this.onRidersTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 319,
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF1F2937),
      child: Stack(
        children: [
          // Settings Title
          Positioned(
            left: 57.60,
            top: 55,
            child: SizedBox(
              width: 189.04,
              height: 36,
              child: Text(
                'Settings',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          
          // Riders Button
          Positioned(
            left: 0,
            top: 116,
            right: 0,
            child: InkWell(
              onTap: onRidersTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const Text(
                  'Riders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Log out Button
          Positioned(
            left: 0,
            top: 144,
            right: 0,
            child: InkWell(
              onTap: onLogoutTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const Text(
                  'Log out',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          
          // Logo at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: Image.asset(
                'images/logo1.png',
                width: 35.27,
                height: 42.50,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileContent extends StatefulWidget {
  const ProfileContent({super.key});

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  String shopName = '';
  String contactNumber = '';
  String address = '';
  double? latitude;
  double? longitude;
  String? photoPath;
  

  // Used to compute distance in kilometers
final Distance _distance = const Distance();

// Carig Sur “center” and maximum allowed radius (1 km)  
final LatLng _allowedCenter = LatLng(17.6607, 121.7525);
final double _allowedRadiusKm = 1.0;
final MapController _mapController = MapController();


// Returns true if `point` is within `radiusKm` of `center`
bool _isWithinRadius(LatLng center, LatLng point, double radiusKm) {
  return _distance.as(LengthUnit.Kilometer, center, point) <= radiusKm;
}

  // For map fallback:
  // static const LatLng _defaultCenter = LatLng(17.6157, 121.7244);
  late LatLng _currentMarker;

  // ignore: unused_field
  XFile? _pickedImage;


  bool isEditingShopName = false;
  bool isEditingContactNumber = false;
  bool isEditingAddress = false; // ← new

  bool isLoading = true;
  bool isSaving = false;

  late TextEditingController shopNameController;
  late TextEditingController contactNumberController;
  late TextEditingController addressController; // ← new

  @override
  void initState() {
    super.initState();
    shopNameController = TextEditingController();
    contactNumberController = TextEditingController();
    addressController         = TextEditingController(); // ← new
    _loadProfile();
  }

  @override
  void dispose() {
    shopNameController.dispose();
    contactNumberController.dispose();
     addressController.dispose(); // ← new
    super.dispose();
  }

  Future<void> _loadProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final uri = Uri.parse('$_apiBase/api/owner/profile');
    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (kDebugMode) {
      debugPrint('[_loadProfile] ${res.statusCode} → ${res.body}');
    }
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;

      setState(() {
        shopName        = body['shop_name']      ?? '';
        contactNumber   = body['contact_number'] ?? '';
        address         = body['address']        ?? '';
        latitude        = (body['latitude'] as num?)?.toDouble();
        longitude       = (body['longitude'] as num?)?.toDouble();
        photoPath       = body['shop_photo'];

        // Populate controllers:
        shopNameController.text      = shopName;
        contactNumberController.text = contactNumber;
        addressController.text       = address;

        // Initialize the map marker:
        if (latitude != null && longitude != null) {
          _currentMarker = LatLng(latitude!, longitude!);
        } else {
          // If no saved coords, default to Carig Sur center
          _currentMarker = _allowedCenter;
        }

        isLoading = false;
      });
    } else {
      throw Exception('HTTP ${res.statusCode}');
    }
  } catch (e) {
    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading profile: $e')),
    );
  }
}




  Future<void> _saveProfile() async {
  // **Client-side check for “Carig Sur”**:
  final addrText = addressController.text.trim();
  if (!addrText.toLowerCase().contains('carig')) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address must be located in Carig Sur.')),
    );
    return;
  }

  setState(() => isSaving = true);
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    final res = await http.patch(
      Uri.parse('$_apiBase/api/owner/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'shop_name'      : shopNameController.text.trim(),
        'contact_number' : contactNumberController.text.trim(),
        'address'        : addressController.text.trim(),
        'latitude'       : latitude,   // ← now updated when tapping map
        'longitude'      : longitude,  // ← now updated when tapping map
      }),
    );

    if (res.statusCode == 200) {
      // **Success → update local state**
      setState(() {
        shopName        = shopNameController.text.trim();
        contactNumber   = contactNumberController.text.trim();
        address         = addressController.text.trim();
        isEditingShopName       = false;
        isEditingContactNumber  = false;
        isEditingAddress        = false; // ← new
        isSaving = false;
      });
      // Persist new shop name if needed
      await prefs.setString('shop_name', shopNameController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } else if (res.statusCode == 422) {
      // **Validation errors from backend**
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final firstError = (body['errors'] as Map<String, dynamic>)
          .values
          .cast<List<dynamic>>()
          .first[0] as String;
      throw Exception(firstError);
    } else {
      throw Exception('Status ${res.statusCode}');
    }
  } catch (e) {
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error saving profile: $e')),
    );
  }
}


Future<void> _onEditPhoto() async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  setState(() {
    _pickedImage = picked;
    isSaving = true;
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token') ?? '';
  final uri = Uri.parse('$_apiBase/api/owner/profile/photo');

  final req = http.MultipartRequest('POST', uri)
    ..headers['Authorization'] = 'Bearer $token'
    ..files.add(await http.MultipartFile.fromPath('shop_photo', picked.path));

  final res = await req.send();
  final body = await res.stream.bytesToString();

  if (res.statusCode == 200) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    setState(() {
      photoPath = data['shop_photo']; 
      _pickedImage = null;
      isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop photo updated!')),
    );
  } else {
    setState(() => isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to upload photo (${res.statusCode})')),
    );
  }
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

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1EFEC),//1F2937
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top section
            Container(
              width: double.infinity,
              height: h(170) + topPadding,
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),//F1EFEC
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
    // Background circle
    CircleAvatar(
      radius: w(62), // half of 125
      backgroundColor: const Color(0xFFD9D9D9),
      backgroundImage: (photoPath != null && photoPath!.isNotEmpty)
        ? NetworkImage('$_apiBase/storage/${photoPath!}')
        : null,
      child: (photoPath == null || photoPath!.isEmpty)
        ? Icon(Icons.store, size: w(60), color: const Color(0xFF455567))
        : null,
    ),

    // Edit icon
    Positioned(
      right: 0,
      bottom: h(8),
      child: InkWell(
        onTap: _onEditPhoto,
        child: Container(
          width: w(24),
          height: h(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: isSaving
              ? const Padding(
                  padding: EdgeInsets.all(4),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.edit, size: fontSize(14), color: const Color(0xFF1F2937)),
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
                    onSave: () => setState(() => isEditingShopName = false),
                    onEdit: () {
                      shopNameController.text = shopName;
                      setState(() => isEditingShopName = true);
                    },
                  ),

                  // Contact number field
                  _buildEditableField(
                    label: 'Contact Number',
                    value: contactNumber,
                    isEditing: isEditingContactNumber,
                    controller: contactNumberController,
                    fontSize: fontSize,
                    keyboardType: TextInputType.phone,
                    onSave: () => setState(() => isEditingContactNumber = false),
                    onEdit: () {
                      contactNumberController.text = contactNumber;
                      setState(() => isEditingContactNumber = true);
                    },
                  ),


                  const SizedBox(height: 0),

                  // **Address field (NEW)**
                    _buildEditableField(
  label: 'Address',
  value: address,
  isEditing: isEditingAddress,
  controller: addressController,
  fontSize: fontSize,
  onSave: () => setState(() => isEditingAddress = false),
  onEdit: () {
    addressController.text = address;
    setState(() => isEditingAddress = true);
  },
),

                    const SizedBox(height: 20),

                    // Only show the map when the user is actively editing the address:
if (isEditingAddress) ...[
  const SizedBox(height: 12),

  // Container for the FlutterMap:
  SizedBox(
    height: h(200),
    child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentMarker,
        initialZoom: 15.0,
        // Only allow tap if within Carig Sur
        onTap: (tapPosition, point) async {
  // 1) Check if tapped point is within your Carig Sur radius
  if (!_isWithinRadius(_allowedCenter, point, _allowedRadiusKm)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Location must be within 10 km of Carig Sur, Tuguegarao City.',
        ),
        backgroundColor: Colors.red,
      ),
    );
    return; // stop here if outside radius
  }

  // 2) Move the pin
  setState(() {
    _currentMarker = point;
  });
  _mapController.move(point, 15.0);

  // 3) Reverse-geocode (to fill the text field), but do NOT reject it if the string
  //    doesn’t literally say “Carig Sur.”
  try {
    final placemarks = await placemarkFromCoordinates(
      point.latitude,
      point.longitude,
    );
    if (placemarks.isNotEmpty) {
      final pm = placemarks.first;
      final newAddr = [
        if (pm.street != null && pm.street!.isNotEmpty) pm.street,
        if (pm.subLocality != null && pm.subLocality!.isNotEmpty)
          pm.subLocality,
        if (pm.locality != null && pm.locality!.isNotEmpty)
          pm.locality,
        if (pm.administrativeArea != null && pm.administrativeArea!.isNotEmpty)
          pm.administrativeArea,
        if (pm.postalCode != null && pm.postalCode!.isNotEmpty)
          pm.postalCode,
        if (pm.country != null && pm.country!.isNotEmpty) pm.country,
      ].where((s) => s != null && s.isNotEmpty).join(', ');

      // 4) Update the address field + state unconditionally (since we already
      //    know the pin is within radius). Do NOT re-check “.contains('carig sur')”.
      setState(() {
        addressController.text = newAddr;
        address = newAddr;
        latitude = point.latitude;
        longitude = point.longitude;
      });
    }
  } catch (err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error reverse-geocoding: $err'),
        backgroundColor: Colors.red,
      ),
    );
  }
},
      ),
      children: [
        // 5.1) Tile layer (OpenStreetMap)
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),

        // 5.2) Marker layer (our pin)
        MarkerLayer(
          markers: [
            Marker(
              width: 40,
              height: 40,
              point: _currentMarker,
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

  const SizedBox(height: 16),
],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: isSaving ? null : _saveProfile,
                        child: Container(
                          width: w(96),
                          height: w(36),
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
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Save',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontSize(14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
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
    // label
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
    // value or editor
    Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, right: 12),
      child: isEditing
          ? TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboardType,
              onSubmitted: (_) => onSave(),
              // only for phone field:
              inputFormatters: label == 'Contact Number'
                  ? <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ]
                  : null,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                // only for phone:
                prefixText: label == 'Contact Number' ? '+63 ' : null,
              ),
              style: TextStyle(
                fontSize: fontSize(16),
                fontWeight: FontWeight.w500,
              ),
            )
          : Text(
              // show +63 for phone, otherwise just the raw value
              label == 'Contact Number' ? '+63$value' : value,
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