import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moodly/screens/auth/login_screen.dart';
import 'package:moodly/screens/home_screen.dart';
import 'package:moodly/utilites/app_onlinebutton.dart';
import 'package:moodly/utilites/app_textfield.dart';
import 'package:moodly/utilites/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/entity/auth_result.dart';
import 'package:twitter_login/twitter_login.dart';

class signup_screen extends StatefulWidget {
  const signup_screen({super.key});

  @override
  _signup createState() => _signup();
}

class _signup extends State<signup_screen> {
  late TapGestureRecognizer loginOnTap;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  String? errorMessage;
  bool _isLoading = false;
  bool _isButtonEnabled = false; // Add this line
  // and you can't declare non nullable fields without intializing them
  // so to solve this mark them as late that is they will be intialized later in the initstate.
  // here you can't declare registerOnTap as nullable
  // because when you are trying to access onTap without handling the possiblity that registerOnTap might be null.
  // anything intialized in initState should never be null when you are setting onTap.

  @override
  void initState() {
    super.initState();
    loginOnTap = TapGestureRecognizer();
    loginOnTap.onTap = () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const login_screen(),
        ),
      );
    };
    _emailController.addListener(_checkFieldsFilled);
    _passwordController.addListener(_checkFieldsFilled);
    _fullNameController.addListener(_checkFieldsFilled);
    _companyNameController.addListener(_checkFieldsFilled);
  }

  // authentication logic handling code
  Future<void> _signupScreen() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final email = _emailController.text;
      final password = _passwordController.text;
      final fullName = _fullNameController.text; //Retrieve full name
      //Attempt to signup with the email and password
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      //Get the firebase user
      final User? user = userCredential.user;
      // Only navigate if the user registration is successful
      if (user != null) {
        // Set the display name for the user
        await user.updateDisplayName(fullName);
        await user.reload(); // Refresh the user to apply changes
        final updatedUser = _auth.currentUser;
        //Store additional user info in the Firestore
        /*await firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': fullName, // store the name here
          'email': user.email,
          'signUpDate': Timestamp.now(),
        }); */
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(user: updatedUser!), // Pass updated user
          ),
        );
      }
      // on success the user will automatically be directed to the HomeScreen
    } on FirebaseAuthException catch (e) {
      // show error if login fails
      _showError(e.message ?? 'Registration Failed');
    } finally {
      setState(() {
        _isLoading = false; // hide the loading spinner
      });
    }
  }

  Future<User?> _signUpWithFacebook() async {
    try {
      // Trigger Facebook Login
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken accessToken = result.accessToken!;
        final String fbToken = accessToken.tokenString;
        // Use the token to authenticate with Firebase
        final AuthCredential credential =
            FacebookAuthProvider.credential(fbToken);
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        return userCredential.user;
        //Navigate to the home screen
        // do it in the button
      } else if (result.status == LoginStatus.cancelled) {
        print("Facebook login cancelled");
      } else {
        print("Facebook login failed: ${result.message}");
      }
    } catch (e) {
      print("Error during Facebook signup: $e");
    }
    return null;
  }

  Future<User?> signUpWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print("Google sign-in canceled");
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user != null) {
        final DocumentSnapshot userDoc =
            await firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          print("User already registered. Please log in.");
          return null;
        } else {
          await firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName,
            'email': user.email,
            'profilePhoto': user.photoURL,
            'signUpDate': Timestamp.now(),
          });
          print("User registered successfully");
          return user;
        }
      }
    } catch (e) {
      print("Error during Google sign-in: $e");
      return null;
    }
    return null;
  }

  Future<void> signUpWithTwitter() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        // web requires signInWithPopup
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(TwitterAuthProvider());
      } else {
        // Android and IOS use signInWithProvider
        userCredential = await FirebaseAuth.instance
            .signInWithProvider(TwitterAuthProvider());
      }
      User? user = userCredential.user;
      if (user != null) {
        print("User registered: ${user.displayName}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Registration Successful: ${user.displayName}"),
          backgroundColor: Colors.green,
        ));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => HomeScreen(
                      user: user,
                    )));
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _showError(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(errorMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  void _checkFieldsFilled() {
    setState(() {
      _isButtonEnabled = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty &&
          _fullNameController.text.isNotEmpty && // Added
          _companyNameController.text.isNotEmpty; // Added
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView(
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    "assets/register.png",
                    height: 250,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_left),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Text(
              "Sign Up",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Themes.colorHeader,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    asset: "assets/google.png",
                    onTap: () async {
                      User? user = await signUpWithGoogle();
                      if (user != null) {
                        //Proceed with navigation to the home screen if the sign-up is successful
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(user: user),
                          ),
                        );
                      } else {
                        //Show an appropriate message, for example, if the user already exists
                        print("Could not sign up; user may already exist.");
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppOutlineButton(
                    asset: "assets/facebook.png",
                    onTap: () async {
                      User? user = await _signUpWithFacebook();
                      if (user != null) {
                        //Proceed with navigation to the home screen if the sign-up is successful
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(user: user),
                          ),
                        );
                      } else {
                        //Show an appropriate message, for example, if the user already exists
                        print("Could not sign up; user may already exist.");
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppOutlineButton(
                    asset: "assets/twitter.png",
                    onTap: signUpWithTwitter, // call the twitter method
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Or, register with email...",
              style: TextStyle(color: Colors.black38),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _emailController,
              hint: "Email ID",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              hint: "Password",
              icon: Icons.lock,
              isPassword: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _fullNameController,
              hint: "Full Name",
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _companyNameController,
              hint: "Company Name",
              icon: Icons.shop,
            ),
            const SizedBox(height: 20),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromRGBO(178, 218, 242, 1),
                padding: const EdgeInsets.all(16),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(16),
                  ),
                ),
              ),
              // supposed to be shape parameter
              onPressed: _isButtonEnabled
                  ? () async {
                      await _signupScreen(); // call the signup function on the button press
                    }
                  : null,

              child: const Text(
                "Register",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ), // Disable the buttom if not enabled
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: "Already have an account? ",
                children: [
                  TextSpan(
                    text: "Login",
                    style: const TextStyle(
                      color: Themes.colorPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: loginOnTap,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            )
          ],
        ),
      ),
    );
  }
}
