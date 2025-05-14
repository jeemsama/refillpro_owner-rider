import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refillpro_owner_rider/views/auth/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Only set preferred orientations
  // REMOVE ALL STATUS BAR STYLING FROM HERE
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RefillPro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // REMOVE ANY appBarTheme that sets systemOverlayStyle
      ),
      home: const LoginScreen(),
    );
  }
}
