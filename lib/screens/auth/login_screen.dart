import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:moodly/screens/auth/signup_screen.dart';
import 'package:moodly/screens/home_screen.dart';
import 'package:moodly/utilites/app_onlinebutton.dart';
import 'package:moodly/utilites/app_textfield.dart';
import 'package:moodly/utilites/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class login_screen extends StatefulWidget {
  const login_screen({super.key});

  @override
  _login createState() => _login();
}

class _login extends State<login_screen> {
  late TapGestureRecognizer registerOnTap;
  // create a googleSignIn instance.
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? errorMessage;
  bool _isLoading = false;
  bool _isLoginButtonEnabled = false;

  // to show a loading spinner during the authentication
  // to show error if the login is going to fail
  // and you can't declare non nullable fields without intializing them
  // so to solve this mark them as late that is they will be intialized later in the initstate.
  // here you can't declare registerOnTap as nullable
  // because when you are trying to access onTap without handling the possiblity that registerOnTap might be null.
  // anything intialized in initState should never be null when you are setting onTap.

  @override
  void initState() {
    super.initState();
    // clear any existing session
    FirebaseAuth.instance.signOut();
    registerOnTap = TapGestureRecognizer();
    registerOnTap.onTap = () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const signup_screen(),
        ),
      );
    };
    _emailController.addListener(_checkLoginFieldsFilled);
    _passwordController.addListener(_checkLoginFieldsFilled);
  }

  void _checkLoginFieldsFilled() {
    setState(() {
      _isLoginButtonEnabled = _emailController.text.isNotEmpty &&
          _passwordController.text.isNotEmpty;
    });
  }

  @override
  void dispose() {
    registerOnTap.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // authentication logic handling code
  Future<void> _loginWithEmailPassword() async {
    setState(() {
      _isLoading = true; // show loading
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      // Attempt to signin with email and password
      /*UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ); */
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // Access the user instance
      User? user = userCredential.user;
      if (user != null) {
        _navigateToHome(context, user);
      } else {
        _showError('User not found');
      }

      //_navigateToHome(context, HomeScreen(user: null,));
      //navigate function
      // On success the user will automatically be directed to the HomeScreen by the authgate
    } on FirebaseAuthException catch (e) {
      // show error if login fails
      _showError(e.message ?? 'Login Failed');
      switch (e.code) {
        case 'invalid-email':
          _showError("Invalid email format.");
          break;
        case 'user-disabled':
          _showError("This account has been disabled");
          break;
        case 'user-not-found':
          _showError("No user found with this email.");
          break;
        case 'wrong-password':
          _showError("Incorrect password");
          break;
        default:
          _showError(e.message ?? 'An error occurred. Please try again.');
      }
    } finally {
      setState(() {
        _isLoading = false; // hide the loading spinner
      });
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      // check if the user is already logged in to Facebook
      final result = await FacebookAuth.instance
          .login(permissions: ['email', 'public_profile']);

      if (result.status == LoginStatus.success) {
        // Facebook login was successful, retrieve the access token
        final accessToken = result.accessToken;

        // check if the access token is not null
        if (accessToken != null) {
          // Create a FacebookAuthCredential to authenticate with Firebase
          final facebookAuthCredential =
              FacebookAuthProvider.credential(accessToken.tokenString);

          // Sign in to Firebase using FacebookAuthCredential
          UserCredential userCredential =
              await _auth.signInWithCredential(facebookAuthCredential);

          // handle the user information here
          User? user = userCredential.user;
          print("Signed in as ${user?.displayName}");
          // Navigate to the home screen or the next screen after successful login
          if (user != null) {
            //Navigate to home screen or dashboard after successful login
            //Navigator.pushReplacementNamed(context, '/home');
            _navigateToHome(context, user);
          }
        }
      } else {
        print("Facebook login failed: ${result.status}");
      }
    } catch (e) {
      print("Error during Facebook sign-in: $e");
    }
  }

  //function to implement Google Sign-In Flow.
  Future<User?> signInWithGoogle() async {
    try {
      // Step 1: Google sign-in flow
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      // check if the sign-in process returned a valid account
      if (googleSignInAccount != null) {
        // Step 2: get authentication tokens
        final GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        // Step 3: Create a credential with tokens
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        // Step 4: Sign in with the credential
        UserCredential userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
        // Step 5: Retrieve the User object
        User? user = userCredential.user;
        if (user != null) {
          _navigateToHome(context, user); // Pass the user to navigate
        } else {
          _showError('User not found');
        }
      } else {
        _showError('Google sign-in canceled.');
      }
    } catch (e) {
      print(e.toString());
      _showError("Google Sign-In failed. Please try again.");
    }
    return null;
  }

  Future<void> signInWithTwitter() async {
    try {
      UserCredential userCredential;
      if (kIsWeb) {
        //Web requires signInWithPopUp
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(TwitterAuthProvider());
      } else {
        //Android and IOS use signInWithPorvider
        userCredential = await FirebaseAuth.instance
            .signInWithProvider(TwitterAuthProvider());
      }
      User? user = userCredential.user;
      if (user != null) {
        print("User logged in: ${user.displayName}");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Login Successful: ${user.displayName}"),
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

  void _navigateToHome(BuildContext context, User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
    );
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
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ListView(
          children: [
            Image.asset(
              "assets/login.png",
              height: 250,
            ),
            const Text(
              "Login",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Themes.colorHeader,
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              hint: "Email ID",
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress, // Email keyboard type
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _passwordController,
              isPassword: true,
              hint: "Password",
              icon: Icons.lock,
              helpContent: const Text(
                "Forgot?",
                style: TextStyle(fontSize: 16, color: Themes.colorPrimary),
              ),
              helpOnTap: () {},
            ),
            const SizedBox(height: 12),
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
              onPressed: _isLoginButtonEnabled
                  ? () async {
                      await _loginWithEmailPassword();
                    }
                  : null,

              child: const Text(
                "Login",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.black),
              )
            ],
            const SizedBox(height: 24),
            const Text(
              "Or, login with...",
              style: TextStyle(color: Colors.black38),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    asset: "assets/google.png",
                    onTap: () async {
                      User? user = await signInWithGoogle();
                      if (user != null) {}
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppOutlineButton(
                    asset: "assets/facebook.png",
                    onTap: signInWithFacebook, //Calls Facebook login function
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppOutlineButton(
                    asset: "assets/twitter.png",
                    onTap: signInWithTwitter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: "New to Moodly? ",
                children: [
                  TextSpan(
                    text: "Register",
                    style: const TextStyle(
                      color: Themes.colorPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    recognizer: registerOnTap,
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

  /*@override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  } */
}
