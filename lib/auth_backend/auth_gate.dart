import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;

import 'package:flutter/material.dart';
import 'package:moodly/screens/auth/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    //StreamBuilder.stream is being passed FirebaseAuth.instance.authStateChanged
    // the stream will return a Firebase User object if the user has being authenticated otherwise it will return null
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // the code is using snapshot.hasData to check if the value from the stream contains the User object.
        if (!snapshot.hasData) {
          return const login_screen();
          // if there isn't it'll return SignInScreen widget currently the screen won't do anything.
          // will be updated in the next step.
        }
        // if the stream returns a User object it returns home screen which
        // is the main part of the application that only authenticated users can access.
        // return the next screen after the auth completes
        return const login_screen(); // change the screen
      },
    );
  }
}
