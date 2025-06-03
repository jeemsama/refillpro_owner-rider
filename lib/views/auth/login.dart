import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/auth/registration.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:http/http.dart' as http;
import 'package:refillpro_owner_rider/views/rider_screen/rider_home.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'forgot_password.dart';
import 'package:flutter/foundation.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Refill Pro',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> _handleLogin() async {
  final email    = _emailController.text.trim();
  final password = _passwordController.text.trim();
  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both email and password')),
    );
    return;
  }

  setState(() => isLoading = true);
  try {
    // 1) Log in
    final loginUrl = Uri.parse('http://192.168.1.22:8000/api/login');
    final loginResponse = await http
      .post(
        loginUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      )
      .timeout(const Duration(seconds: 10));

    debugPrint('Login ${loginResponse.statusCode} → ${loginResponse.body}');
    final loginData = jsonDecode(loginResponse.body) as Map<String, dynamic>;

    final token = loginData['token'] as String?;
    final user  = loginData['user']  as Map<String, dynamic>?;
    final role  = user?['role'] as String?;

    if (loginResponse.statusCode == 200 && token != null && user != null && role != null) {
      // Determine stationOwnerId
      final int? rawUserId = user['id'] as int?;
      final int? stationOwnerId = (role == 'owner')
        ? rawUserId
        : (user['owner_id'] as int?);

      if (stationOwnerId == null) {
        throw 'Missing owner_id in login response';
      }

      // 2) Save token, owner_id, and role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt   ('owner_id',   stationOwnerId);
      await prefs.setString('role',       role);

      if (kDebugMode) {
        debugPrint('Saved auth_token: $token');
        debugPrint('Saved owner_id: $stationOwnerId');
      }

      // 3) Fetch profile so we can extract shop_id from the nested object
      final profileUrl = Uri.parse('http://192.168.1.22:8000/api/owner/profile');
      final profileResponse = await http.get(
        profileUrl,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      debugPrint('Profile ${profileResponse.statusCode} → ${profileResponse.body}');
      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body) as Map<String, dynamic>;

        // ─── CHANGE THIS LINE ─────────────────────────────────────────
        // Instead of:
        // final int? shopIdFromProfile = profileData['shop_id'] as int?;
        //
        // Do this if your API nests the shop id under "owner_shop_details" in the JSON:
        final int? shopIdFromProfile = profileData['shop_id'] as int?;
        // ────────────────────────────────────────────────────────────────

        if (shopIdFromProfile == null) {
          throw 'Missing shop_id in profile response';
        }
        await prefs.setInt('shop_id', shopIdFromProfile);

        if (kDebugMode) debugPrint('Saved shop_id: $shopIdFromProfile');
      } else {
        throw 'Failed to fetch owner profile (status: ${profileResponse.statusCode})';
      }

      // 4) Navigate to the correct home screen
      if (role == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RiderHome()),
        );
      }
      return;
    }

    final err = (loginData['message'] ?? loginData['error'] ?? 'Login failed').toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  } on FormatException {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid response from server.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
}




  void _handleRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const Registration()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth  = screenSize.width;
    final containerWidth = screenWidth * 0.85;
    final buttonWidth    = containerWidth * 0.3;
    final logoTop        = screenHeight * 0.15;
    final formBottom     = screenHeight * 0.20;
    final titleFontSize  = screenWidth * 0.06;
    final labelFontSize  = screenWidth * 0.04;
    final buttonFontSize = screenWidth * 0.025;

    return Scaffold(
      backgroundColor: const Color(0xFF455567),
      body: SingleChildScrollView(
        child: SizedBox(
          width: screenWidth,
          height: screenHeight,
          // decoration: const BoxDecoration(color: Color(0xFF455567)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: logoTop,
                child: Column(
                  children: [
                    Image.asset('images/logo.png', width: 177, height: 271),
                  ],
                ),
              ),

              // Login Container
              Positioned(
                bottom: formBottom,
                child: Container(
                  width: containerWidth,
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF455567),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(width: 1, color: Color(0xFF1F2937)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Log in',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Email Field
                      Row(
                        children: [
                          SizedBox(
                            width: screenWidth * 0.2,
                            child: Text(
                              'Email:',
                              style: TextStyle(
                                color: const Color(0xFFE5E7EB),
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.025,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(fontSize: labelFontSize * 0.9),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.015),

                      // Password Field
                      Row(
                        children: [
                          SizedBox(
                            width: screenWidth * 0.2,
                            child: Text(
                              'Password:',
                              style: TextStyle(
                                color: const Color(0xFFE5E7EB),
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: const Color(0xFFD9D9D9),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.025,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(fontSize: labelFontSize * 0.9),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.025),

                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1A2B),
                              minimumSize: Size(buttonWidth, screenHeight * 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1A2B),
                              minimumSize: Size(buttonWidth, screenHeight * 0.04),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Log in',
                                    style: TextStyle(
                                      fontSize: buttonFontSize,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                  ),
                          ),
                        ],
                      ),

                      // ← NEW: Forgot Password link
                      SizedBox(height: screenHeight * 0.015), // spacing
                      TextButton(
                        onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: labelFontSize * 0.9,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      // ← END NEW
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
