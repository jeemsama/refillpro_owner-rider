import 'package:flutter/material.dart';
import 'package:refillpro_owner_rider/views/auth/registration.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';

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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    // Implement login logic here
    debugPrint('Login button pressed');
    debugPrint('Phone: ${_phoneController.text}');
    debugPrint('Password: ${_passwordController.text}');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Home()),
    );

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
                      'images/logo1.png',
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
                              'Phone:',
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
                              controller: _phoneController,
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
                            width: screenWidth * 0.2, // 20% of width
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
                              obscureText: true,
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
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F1A2B),
                              foregroundColor: Colors.white,
                              minimumSize: Size(buttonWidth, screenHeight * 0.04), // 4% of height
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
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