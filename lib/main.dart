import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:refillpro_owner_rider/views/auth/login.dart';
// import 'package:refillpro_owner_rider/views/owner_screen/home.dart';
import 'package:refillpro_owner_rider/views/splash_screen.dart';   // ← add this

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Only set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Future<bool> _hasToken() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   // change 'customer_token' if you used a different key
  //   return prefs.getString('auth_token') != null;
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RefillPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Only one `home:` allowed—launch the splash screen first
      home: const SplashScreen(),
    );
  }
}
