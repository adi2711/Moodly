import 'dart:async';
import 'package:flutter/material.dart';
import "package:moodly/screens/auth/user_auth_onboard.dart"; // Replace with your actual home screen widget

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

// extending the state class with singleTickerProviderStateMixin makes it a ticker
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  // Fundamental and basic things needed to make an animation:
  //--> controller-- controls everything.
  //--> ticker -- gives life to the animation.
  //--> tween -- to map the value of that ticker to the value you can use.
  //--> curves -- all tweens have a default tween curve.

  @override
  void initState() {
    super.initState();
    // Animation Controller contains methods that start and stop an animation, reset animations, play animations in reverse.
    // has getters that give info about animation as it happens.
    // animation controller takes in two parameters: Ticker and Time duration
    _controller = AnimationController(
      vsync: this, // must pass a ticker into the vsync property
      duration: const Duration(
          seconds:
              2), // length of time animation lasts from the animation controller's start to finish.
    );
    // the default range of interpolation for a AnimationController ranges from 0.0 to 1.0.
    // for a different range or data type use TWEEN  where you can define the range by
    // tween<>(begin: , end: )
    // ex : ColorTween(begin: Colors.transparent, end: Colors.black54)
    // this ColorTween specifies progression between two colors.
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    // curvedAnimation defines the animation progress as a non-linear curve.
    // syntax: CurvedAnimation(parent: controller, curve: Curves.easeIn/ Curves.easeOut)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: const Offset(0, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    //Start an animation with the .forward() method
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) =>
                const user_auth_onboard()), // Replace with your home screen
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/splashScreen.jpg', // Replace with your image asset
            fit: BoxFit.cover,
          ),
          // Logo with slide and fade animations
          Center(
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/logo.png', // Replace with your logo asset
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
