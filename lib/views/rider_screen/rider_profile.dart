import 'package:flutter/material.dart';

class RiderProfile extends StatelessWidget {
  const RiderProfile({super.key});

  @override
  Widget build(BuildContext context) {
    // just your profile UI — no Scaffold here!
    return Center(
      child: Text(
        'Your Profile',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
      ),
    );
  }
}
