import 'package:aifinance/pages/auth/login/Login.dart';
import 'package:aifinance/pages/auth/signup/Singup.dart';
import 'package:aifinance/pages/auth/signup/Verify.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  bool loginUI = true;
  bool isLoading = false;
  void savedLogIn() {
    setState(() {
      isLoading = true;
    });
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user == null) {
        print('User is currently logged out!');
      } else {
        print('User logged in!');
        // navigate
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => Home()));
      }
    });
    setState(() {
      isLoading = false;
    });
  }

  void logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Auth()),
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  @override
  void initState() {
    savedLogIn();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                child: loginUI ? Login() : Signup(),
              ),
              TextButton(
                  onPressed: () {
                    setState(() {
                      loginUI = !loginUI;
                    });
                  },
                  child: Text(loginUI ? "Or Sign Up" : "Or Log In"))
            ],
          ),
        ),
      ),
    );
  }
}
