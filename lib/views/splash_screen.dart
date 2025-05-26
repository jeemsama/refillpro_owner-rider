import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refillpro_owner_rider/views/auth/login.dart';
import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/rider_screen/rider_home.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
  await Future.delayed(const Duration(seconds: 2));
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final role  = prefs.getString('role');

  Widget destination;
  if (token != null && role == 'owner') {
    destination = const Home();       // owner home
  } else if (token != null && role == 'rider') {
    destination = const RiderHome();  // rider home
  } else {
    destination = const LoginScreen(); // not logged in
  }

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => destination),
  );
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Set logo width to 40% of screen width, height auto
    final logoWidth = size.width * 0.4;
    // Set vertical spacing
    final spacing16 = size.height * 0.02; // ~16px on 800px height
    final spacing8 = size.height * 0.01;
    // Text sizes
    // final titleSize = size.width * 0.06; // ~24px on 400px width
    // final subtitleSize = size.width * 0.055;

    return Scaffold(
      backgroundColor: const Color(0xFF455567),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'images/logo.png',
              width: logoWidth,
              // height can adjust to maintain aspect ratio
            ),
            SizedBox(height: spacing16),
            // Text(
            //   'RefillPro',
            //   style: TextStyle(
            //     color: Colors.white,
            //     fontSize: titleSize,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            SizedBox(height: spacing8),
            // Text(
            //   'Owner',
            //   style: TextStyle(
            //     color: Colors.white70,
            //     fontSize: subtitleSize,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
