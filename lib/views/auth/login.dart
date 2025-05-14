import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/auth/registration.dart';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'package:refillpro_owner_rider/views/owner_screen/add_rider.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/rider_screen/maps.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';



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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
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
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter both email and password')),
    );
    return;
  }

  setState(() => isLoading = true);
  try {
    final url = Uri.parse('http://192.168.1.7:8000/api/login');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    ).timeout(const Duration(seconds: 10));

    // Will throw if the server returns HTML instead of JSON
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['token'] != null) {
      final token  = data['token'] as String;
      final role   = data['role']  as String? ?? '';
      // final status = data['user']['status'] as String? ?? '';

      // if (status != 'approved') {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     const SnackBar(content: Text('Account not approved yet')),
      //   );
      //   return;
      // }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      if (role == 'owner') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      } else if (role == 'rider') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Maps()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported role')),
        );
      }
    } else {
      final error = data['message']?.toString() ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  } on FormatException {
    // Catches HTML or invalid JSON
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Server returned invalid data.')),
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
    // Implement registration navigation here
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Registration()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    
    // Calculate responsive sizes
    final loginContainerWidth = screenWidth * 0.85; // 85% of screen width
    final buttonWidth = loginContainerWidth * 0.3; // 30% of container width
    
    // Calculate responsive positions
    final logoTopPosition = screenHeight * 0.15; // 15% from top
    final loginContainerBottomPosition = screenHeight * 0.2; // 20% from bottom
    
    // Calculate responsive text sizes
    final titleFontSize = screenWidth * 0.06; // 6% of width
    final labelFontSize = screenWidth * 0.04; // 4% of width
    final buttonFontSize = screenWidth * 0.025; // 2.5% of width
    
    return Scaffold(
      backgroundColor: const Color(0xFF455567),
      body: SingleChildScrollView(
        child: Container(
          width: screenWidth,
          height: screenHeight,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(color: Color(0xFF455567)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Logo
              Positioned(
                top: logoTopPosition,
                child: Column(
                  children: [
                    Image.asset(
                      'images/logo.png',
                      width: 177,
                      height: 271,
                    ),
                    SizedBox(height: screenHeight * 0.0), // 1% of screen height
                  ],
                ),
              ),
              
              // Login Container
              Positioned(
                bottom: loginContainerBottomPosition,
                child: Container(
                  width: loginContainerWidth,
                  padding: EdgeInsets.all(screenWidth * 0.04), // 4% of width
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Log in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize,
                          fontFamily: 'Poppins-ExtraBold.ttf',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02), // 2% of height
                      
                      // Phone TextField
                      Row(
                        children: [
                          SizedBox(
                            width: screenWidth * 0.2, // 20% of width
                            child: Text(
                              'Email:',
                              style: TextStyle(
                                color: const Color(0xFFE5E7EB),
                                fontSize: labelFontSize,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
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
                                  horizontal: screenWidth * 0.025, // 2.5% of width
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              style: TextStyle(fontSize: labelFontSize * 0.9),
                            ),
                          ),
                        ],
                      ),
                      
                      SizedBox(height: screenHeight * 0.015), // 1.5% of height
                      
                      // Password TextField
                      Row(
                        children: [
                          SizedBox(
                            width: screenWidth * 0.2,
                            child: Text(
                              'Password:',
                              style: TextStyle(
                                color: const Color(0xFFE5E7EB),
                                fontSize: labelFontSize,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                                height: 1.25,
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
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                    size: 16, 
                                    color: Colors.grey[600],
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
                      
                      SizedBox(height: screenHeight * 0.025), // 2.5% of height
                      
                      // Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Register Button
                          ElevatedButton(
                            onPressed: _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1A2B),
                              foregroundColor: Colors.white,
                              minimumSize: Size(buttonWidth, screenHeight * 0.04), // 4% of height
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: buttonFontSize,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          
                          // Login Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,        // disable during loading
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1A2B),
                              foregroundColor: Colors.white,
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
                                      color: Colors.white,
                                      fontSize: buttonFontSize,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w400,
                                    ),
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
      ),
    );
  }
}