import 'package:aifinance/database/basicTypes.dart';
import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  late FirebaseFirestore db;
  final TextEditingController _emailSignup = TextEditingController();
  final TextEditingController _pwSignup = TextEditingController();
  final TextEditingController _pwconfirm = TextEditingController();

  late User user;
  bool hidePw = true;
  bool goVerify = false;

  bool isLoading = false;

  String errorMessage = '';

  void userSignUp() async {
    if (_pwSignup.text != _pwconfirm.text) {
      setState(() {
        errorMessage = 'Your confirmation password does not equal to password.';
      });

      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailSignup.text.trim(),
        password: _pwSignup.text.trim(),
      );

      await setDefaultTypes();
      Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
      // handle add to cloud
      print('signingup');
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.code;
      });
      if (e.code == 'weak-password') {
        setState(() {
          errorMessage = 'The password provided is too weak.';
        });
      } else if (e.code == 'email-already-in-use') {
        setState(() {
          errorMessage = 'The account already exists for that email.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> setDefaultTypes() async {
    int index = 0;
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        final currencyDoc = db
            .collection("items")
            .doc(user.email)
            .collection("currency")
            .doc("currency")
            .set({"currency": "USD"});

        final typeCollection = db
            .collection("items")
            .doc(user.email)
            .collection('types')
            .withConverter(
              fromFirestore: ItemType.fromFirestore,
              toFirestore: (ItemType type, options) => type.toFirestore(),
            );
        for (var types in defaultTypes) {
          final typeDocRef = await typeCollection.add(types);
          final cateCollection = typeCollection
              .doc(typeDocRef.id)
              .collection("categories")
              .withConverter(
                fromFirestore: ItemCategory.fromFirestore,
                toFirestore: (ItemCategory category, options) =>
                    category.toFirestore(),
              );
          for (var categories in defaultCategories[index]) {
            await cateCollection.add(categories);
          }
          index = index + 1;
        }

        final capitalCollection = db
            .collection("items")
            .doc(user.email)
            .collection("capitals")
            .withConverter(
                fromFirestore: Capital.fromFirestore,
                toFirestore: (Capital capital, options) =>
                    capital.toFirestore());

        for (var capital in defaultCapital) {
          await capitalCollection.add(capital);
        }
        return;
      } else {
        return;
      }
    });
  }

  @override
  void initState() {
    db = FirebaseFirestore.instance;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text('Sign Up', style: TextStyle(fontSize: 20))],
        ),
        Text('email'),
        TextField(
          controller: _emailSignup,
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
          controller: _pwSignup,
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
        Text('Confirm Password'),
        TextField(
          obscureText: hidePw,
          controller: _pwconfirm,
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
                  if (_pwSignup.text == _pwconfirm.text &&
                      _emailSignup.text != '') {
                    userSignUp();
                  } else if (_pwSignup.text == '' ||
                      _pwSignup.text == '' ||
                      _emailSignup.text != '') {
                    setState(() {
                      errorMessage = 'Please fill in all items!';
                    });
                  }
                },
                style: TextButton.styleFrom(backgroundColor: Colors.indigo),
                child: Padding(
                  padding: EdgeInsets.only(left: 36.0, right: 36.0),
                  child: Text(
                    goVerify ? "Continue to Verify" : 'Sign Up',
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
