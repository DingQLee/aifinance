import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/AllCapitals/EditCapital.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:aifinance/widgets/AmountInput.dart';
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

  final TextEditingController _amount = TextEditingController();

  List<Capital> capitals = [];

  List<TotalCapital> totalAssetList = [];
  List<TotalCapital> totalLiabilityList = [];

  Capital cap1 = Capital();
  Capital cap2 = Capital();
  bool setCapMode = false;
  bool setCap1 = true;

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

  void selectCapital(Capital cap) {
    if (cap == cap1) {
      setState(() {
        setCap1 = true;
        setCapMode = true;
      });
    } else {
      setState(() {
        setCap1 = false;
        setCapMode = true;
      });
    }
  }

  void updateCapital() async {
    double transferAmount = double.parse(_amount.text);

    if (transferAmount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot transfer amount of 0.")),
      );
      return;
    }

    if (cap1.id == cap2.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cannot transfer to the same capital!")),
      );
      return;
    }

    if (cap1.amount! < transferAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Insufficient amount in ${cap1.type}.")),
      );
      return;
    }

    if (cap2.amount! < transferAmount && cap2.source == "Liability") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Insufficient amount in ${cap1.type}.")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final double originCap1 = cap1.amount!;
    final double originCap2 = cap2.amount!;

    final capital1Ref = db
        .collection("items")
        .doc(user.email)
        .collection('capitals')
        .doc(cap1.id);

    if (cap1.source == "Asset") {
      await capital1Ref.update({
        "amount": cap1.amount! - transferAmount,
      });
    } else {
      await capital1Ref.update({
        "amount": cap1.amount! + transferAmount,
      });
    }
    final capital2Ref = db
        .collection("items")
        .doc(user.email)
        .collection('capitals')
        .doc(cap2.id);
    if (cap2.source == "Asset") {
      await capital2Ref.update({
        "amount": cap2.amount! + transferAmount,
      });
    } else {
      await capital2Ref.update({
        "amount": cap2.amount! - transferAmount,
      });
    }

    setState(() {
      cap1 = Capital();
      cap2 = Capital();
      _amount.text = '';
    });
    await getCapitals();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Transfer successful!"),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            setState(() {
              isLoading = false;
            });
            await capital1Ref.update({
              "amount": originCap1,
            });
            await capital2Ref.update({
              "amount": originCap2,
            });
            setState(() {
              cap1 = Capital();
              cap2 = Capital();
            });
            await getCapitals();
            setState(() {
              isLoading = false;
            });
          },
        ),
      ),
    );
    setState(() {
      isLoading = false;
    });
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
        title: Row(
          children: [
            Image.asset(
              "assets/images/icons/balance.png",
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
            Text(' Assets and Liabilities'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ...totalAssetList.map((total) => ListTile(
                  title: Text('Total Assets in ${total.currency}'),
                  subtitle: Text('\$${total.amount.toStringAsFixed(2)}'),
                )),
            ...totalLiabilityList.map((total) => ListTile(
                  title: Text('Total Liabilities in ${total.currency}'),
                  subtitle: Text('\$${total.amount.toStringAsFixed(2)}'),
                )),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      TextButton(
                          onPressed: () {
                            selectCapital(cap1);
                          },
                          child: Text(cap1.type ?? "From")),
                      TextButton(
                          onPressed: () {
                            selectCapital(cap2);
                          },
                          child: Text(cap2.type ?? "To")),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Text('Amount'),
                      cap1 == cap2
                          ? Text('Cannot Trasfer Same!')
                          : AmountInput(amount: _amount, onChanged: (value) {})
                    ],
                  ),
                ),
                Expanded(
                    flex: 1,
                    child: TextButton(
                        onPressed: () {
                          if (cap1.id == cap2.id) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      "Cannot transfer to the same capital!")),
                            );
                            return;
                          }
                          updateCapital();
                        },
                        child: Text("Transfer"))),
              ],
            ),
            Column(
              children: List.generate(
                  capitals.length,
                  (index) => GestureDetector(
                        onTap: () {
                          if (setCapMode) {
                            if (setCap1) {
                              setState(() {
                                cap1 = capitals[index];
                                setCapMode = false;
                              });
                            } else {
                              setState(() {
                                cap2 = capitals[index];
                                setCapMode = false;
                              });
                            }
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        EditCapital(capital: capitals[index])));
                          }
                        },
                        child: _capitalRow(capitals[index]),
                      )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _capitalRow(Capital thisCap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        color: setCapMode ? Colors.green : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(thisCap.type!),
                    Visibility(
                        visible: thisCap.fav,
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                        ))
                  ],
                ),
                Text(thisCap.source!),
              ],
            ),
            Text('${thisCap.currency} ${thisCap.amount!.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
