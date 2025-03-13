import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:aifinance/pages/loadingScereen/LoadingScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:forex_currency_conversion/forex_currency_conversion.dart';

class CurrencySetting extends StatefulWidget {
  const CurrencySetting({super.key});

  @override
  State<CurrencySetting> createState() => _CurrencySettingState();
}

class _CurrencySettingState extends State<CurrencySetting> {
  late FirebaseFirestore db;
  late User user;

  UserCurrency currency = UserCurrency(currency: "");
  List<ExchangePair> exchangePairs = [];

  String newCur1 = 'Currency 1';
  String newCur2 = 'Currency 2';

  bool isLoading = false;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      setState(() {
        isLoading = true;
      });
      if (_user != null) {
        user = _user;
        await getCurrency();
        await getExchangePair();
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  void saveCurrency() async {
    await db
        .collection("items")
        .doc(user.email)
        .collection("currency")
        .doc("currency")
        .set({"currency": currency.currency});
    await getCurrency();
    const snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.none,
        content: Text('Currency Change Made!'));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> addExchangePair() async {
    setState(() {
      isLoading = true;
    });
    try {
      final exchangeDoc =
          db.collection("items").doc(user.email).collection("exchange").doc();
      await exchangeDoc.set({"cur1": newCur1, "cur2": newCur2});
      await getExchangePair();
      const snackBar = SnackBar(
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.none,
          content: Text('Currency Change Made!'));

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      print("Error adding pairs: $e");
    }
    setState(() {
      isLoading = true;
    });
  }

  Future<void> getExchangePair() async {
    try {
      final ref = await db
          .collection("items")
          .doc(user.email)
          .collection("exchange")
          .get();
      exchangePairs = ref.docs.map((docSnapshot) {
        return ExchangePair.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();
    } catch (e) {
      print("Error getting pairs: $e");
    }
  }

  Future<void> getCurrency() async {
    try {
      final ref = db
          .collection("items")
          .doc(user.email)
          .collection("currency")
          .doc("currency")
          .withConverter(
            fromFirestore: UserCurrency.fromFirestore,
            toFirestore: (UserCurrency currency, _) => currency.toFirestore(),
          );
      final docSnap = await ref.get();
      currency = docSnap.data()!;
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  void deletePair(String pairID) async {
    await db
        .collection("items")
        .doc(user.email)
        .collection("exchange")
        .doc(pairID)
        .delete()
        .then(
      (doc) async {
        const snackBar = SnackBar(
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.none,
            content: Text('Exchange Pair Deleted!'));

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        await getExchangePair();
        setState(() {});
      },
      onError: (e) => print("Error updating document $e"),
    );
  }

  @override
  void initState() {
    db = FirebaseFirestore.instance;
    getUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (context) => Home())),
            icon: Icon(Icons.arrow_back)),
        title: Text("Currency Settings"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // default currency
                Text("Your Default Currency"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(currency.currency),
                    GestureDetector(
                        onTap: () {
                          showCurrencyPicker(
                            context: context,
                            showFlag: true,
                            showCurrencyName: true,
                            showCurrencyCode: true,
                            onSelect: (Currency thisCurrency) {
                              setState(() {
                                currency.currency = thisCurrency.code;
                                saveCurrency();
                              });
                            },
                          );
                        },
                        child: Icon(Icons.edit)),
                  ],
                ),
                // add exchange pair
                _newPair(),
                // all exchange pair
                Column(
                  children: List.generate(exchangePairs.length,
                      (index) => _exchangePair(exchangePairs[index])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _newPair() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("New Exchange Pair"),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                  onPressed: () {
                    showCurrencyPicker(
                      context: context,
                      showFlag: true,
                      showCurrencyName: true,
                      showCurrencyCode: true,
                      onSelect: (Currency thisCurrency) {
                        setState(() {
                          newCur1 = thisCurrency.code;
                        });
                      },
                    );
                  },
                  child: Text(newCur1)),
              TextButton(
                  onPressed: () {
                    showCurrencyPicker(
                      context: context,
                      showFlag: true,
                      showCurrencyName: true,
                      showCurrencyCode: true,
                      onSelect: (Currency thisCurrency) {
                        setState(() {
                          newCur2 = thisCurrency.code;
                        });
                      },
                    );
                  },
                  child: Text(newCur2)),
            ],
          ),
          Visibility(
              visible: newCur1 != 'Currency 1' && newCur2 != 'Currency 2',
              child: TextButton(
                  onPressed: () async {
                    await addExchangePair();
                  },
                  child: Text("ADD"))),
        ],
      ),
    );
  }

  Widget _exchangePair(ExchangePair pair) {
    return FutureBuilder(
        future: Forex().getCurrencyConverted(
            sourceCurrency: pair.currency1,
            destinationCurrency: pair.currency2,
            sourceAmount: 1),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text('Loading data...');
          } else if (snapshot.hasError) {
            return Text('Error occurs when loading');
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(pair.currency1),
                          Text(pair.currency2),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(pair.currency1),
                          Text(
                            snapshot.data!.toStringAsFixed(3),
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(pair.currency2),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      deletePair(pair.id!);
                    },
                    icon: Icon(Icons.delete),
                  ),
                ],
              ),
            );
          }
        });
  }
}
