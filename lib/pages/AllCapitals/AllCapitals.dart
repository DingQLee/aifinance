import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/AllCapitals/EditCapital.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TotalCapital {
  bool isAsset;
  double amount;
  String currency;

  TotalCapital({
    required this.isAsset,
    required this.amount,
    required this.currency,
  });
}

class AllCapitals extends StatefulWidget {
  const AllCapitals({super.key});

  @override
  State<AllCapitals> createState() => _AllCapitalsState();
}

class _AllCapitalsState extends State<AllCapitals> {
  late FirebaseFirestore db;
  late User user;

  List<Capital> capitals = [];

  List<TotalCapital> totalAssetList = [];
  List<TotalCapital> totalLiabilityList = [];
  bool isLoading = false;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        await fetchCapital();
      }
    });
  }

  Future<void> fetchCapital() async {
    setState(() {
      isLoading = true;
    });
    await getCapitals();
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getCapitals() async {
    try {
      QuerySnapshot querySnapshot = await db
          .collection("items")
          .doc(user.email)
          .collection("capitals")
          .get();

      capitals = querySnapshot.docs.map((docSnapshot) {
        return Capital.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();

      capitals.sort((a, b) => b.fav.toString().compareTo(a.fav.toString()));

      // Reset total lists
      totalAssetList.clear();
      totalLiabilityList.clear();

      for (var capital in capitals) {
        if (capital.source == 'Asset') {
          _updateTotalList(
              totalAssetList, capital.amount!, capital.currency!, true);
        } else {
          _updateTotalList(
              totalLiabilityList, capital.amount!, capital.currency!, false);
        }
      }
    } catch (e) {
      print("Error retrieving items: $e");
    }
  }

  void _updateTotalList(List<TotalCapital> totalList, double amount,
      String currency, bool isAsset) {
    // Check if the currency already exists in the total list
    final existingEntry = totalList.firstWhere(
      (total) => total.currency == currency,
      orElse: () =>
          TotalCapital(isAsset: isAsset, amount: 0, currency: currency),
    );

    if (existingEntry.amount > 0) {
      // If it exists, add the amount to it
      existingEntry.amount += amount;
    } else {
      // If it doesn't exist, add a new entry
      totalList.add(
          TotalCapital(isAsset: isAsset, amount: amount, currency: currency));
    }
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
        title: Text('Assets and Liabilities'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display total assets and liabilities by currency
            ...totalAssetList.map((total) => ListTile(
                  title: Text('Total Assets in ${total.currency}'),
                  subtitle: Text('\$${total.amount.toStringAsFixed(2)}'),
                )),
            ...totalLiabilityList.map((total) => ListTile(
                  title: Text('Total Liabilities in ${total.currency}'),
                  subtitle: Text('\$${total.amount.toStringAsFixed(2)}'),
                )),
            // Display individual capitals
            Column(
              children: List.generate(
                  capitals.length,
                  (index) => GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditCapital(capital: capitals[index]))),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(capitals[index].type!),
                                      Visibility(
                                          visible: capitals[index].fav,
                                          child: Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ))
                                    ],
                                  ),
                                  Text(capitals[index].source!),
                                ],
                              ),
                              Text(
                                  '${capitals[index].currency} ${capitals[index].amount}'),
                            ],
                          ),
                        ),
                      )),
            ),
          ],
        ),
      ),
    );
  }
}
