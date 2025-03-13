import 'dart:async';
import 'package:aifinance/pages/home/Home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  late User user;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? timer;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        setState(() {
          user = _user;
        });
        verifyEmail();
      }
    });
  }

  void verifyEmail() async {
    await FirebaseAuth.instance.setLanguageCode("en");
    await user.sendEmailVerification();
  }

  void checkVerification() async {
    print('verifying!');
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.emailVerified) {
      // User has verified their email
      timer?.cancel(); // Stop the timer
      // Navigate to the next screen or show a success message
      print('VERIFIED!');
      Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();

    // Start the timer to check for verification every 2 seconds
    timer = Timer.periodic(Duration(seconds: 2), (Timer t) {
      checkVerification();
    });
  }

  @override
  void dispose() {
    timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome, and thank you for choosing our app!'),
            Text('This is your email: ${user.email}'),
            Text('We have sent you a verification email.',
                style: TextStyle(fontSize: 20)),
            Text('Please Verify Your Email First.',
                style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
