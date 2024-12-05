import 'dart:async';
import 'package:eco_guardian/LoginRegistrationApp.dart';

import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      // After 3 seconds, navigate to the LoginScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (BuildContext context) => LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Replace 'YourLogo.png' with the path to your logo image
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/adsolution.png'), // Replace 'YourLogo.png'
      ),
    );
  }
}
