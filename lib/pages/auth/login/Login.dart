import 'package:aifinance/pages/home/Home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailLogin = TextEditingController();
  final TextEditingController _pwLogin = TextEditingController();

  bool hidePw = true;

  bool isLoading = false;

  String errorMessage = '';
  void userLogIn() async {
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailLogin.text.trim(),
        password: _pwLogin.text,
      );

      // navigate
      print('logged in!');
      Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.code;
      });
      if (e.code == 'user-not-found') {
        setState(() {
          errorMessage = 'No user found for that email.';
        });
      } else if (e.code == 'wrong-password') {
        setState(() {
          errorMessage = 'Wrong password provided for that user.';
        });
      } else if (e.code == 'invalid-credential') {
        setState(() {
          errorMessage = 'This email is not signed up yet.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An unexpected error occurred.';
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Log In', style: TextStyle(fontSize: 20))],
        ),
        Text('Email'),
        TextField(
          controller: _emailLogin,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
        Text('Password'),
        TextField(
          obscureText: hidePw,
          controller: _pwLogin,
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(4.0),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  hidePw = !hidePw;
                });
              },
              icon: Icon(hidePw
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_outlined),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () async {
                if (_emailLogin.text != '' && _pwLogin.text != '') {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: _emailLogin.text);
                  errorMessage =
                      'We have sent you a reset link. Try again when you are ready!';
                } else {
                  setState(() {
                    errorMessage = 'Please enter your email or password first!';
                  });
                }
              },
              child: Text(
                'Forget Password?',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
        Text(
          errorMessage,
          style: TextStyle(color: Colors.red),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  userLogIn();
                },
                style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 177, 21, 9)),
                child: Padding(
                  padding: EdgeInsets.only(left: 36.0, right: 36.0),
                  child: Text(
                    'Log In',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
