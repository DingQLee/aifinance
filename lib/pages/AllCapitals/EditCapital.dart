import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/AllCapitals/AllCapitals.dart';
import 'package:aifinance/widgets/AmountInput.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditCapital extends StatefulWidget {
  final Capital capital;
  EditCapital({super.key, required this.capital});

  @override
  State<EditCapital> createState() => _EditCapitalState();
}

class _EditCapitalState extends State<EditCapital> {
  late FirebaseFirestore db;
  late User user;

  final TextEditingController _newAmount = TextEditingController();
  final TextEditingController _type = TextEditingController();

  late Capital capital;

  bool isLoading = false;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        _newAmount.text = capital.amount.toString();
        _type.text = capital.type!;
      }
    });
  }

  void updateCapital(Capital capital) async {
    final capitalRef = db
        .collection("items")
        .doc(user.email)
        .collection('capitals')
        .doc(widget.capital.id);
    await capitalRef.update({
      "amount": double.parse(_newAmount.text),
      "currency": capital.currency,
      "fav": capital.fav,
      "source": capital.source,
      "type": _type.text.trim(),
    });
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => AllCapitals()));
  }

  @override
  void initState() {
    db = FirebaseFirestore.instance;
    getUser();
    capital = widget.capital;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(capital.source!),
              Row(
                children: [
                  Text('Set to favorite: '),
                  GestureDetector(
                      onTap: () {
                        setState(() {
                          capital.fav = !capital.fav;
                        });
                      },
                      child: Icon(capital.fav ? Icons.star : Icons.star_border))
                ],
              ),
              TextField(
                controller: _type,
                decoration: InputDecoration(prefix: Text('Type ')),
              ),
              Text('New Amount:'),
              Row(
                children: [
                  Expanded(
                      flex: 1,
                      child: TextButton(
                          onPressed: () {
                            showCurrencyPicker(
                              context: context,
                              showFlag: true,
                              showCurrencyName: true,
                              showCurrencyCode: true,
                              onSelect: (Currency thisCurrency) {
                                setState(() {
                                  capital.currency = thisCurrency.code;
                                });
                              },
                            );
                          },
                          child: Text(capital.currency!))),
                  Expanded(
                      flex: 4,
                      child: AmountInput(
                          amount: _newAmount, onChanged: (value) {})),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel')),
                  TextButton(
                      onPressed: () {
                        updateCapital(capital);
                      },
                      child: Text('Confirm')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
