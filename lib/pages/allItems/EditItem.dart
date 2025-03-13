import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/allItems/AllItems.dart';
import 'package:aifinance/widgets/AmountInput.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class EditItem extends StatefulWidget {
  final Item item;
  const EditItem({super.key, required this.item});

  @override
  State<EditItem> createState() => _EditItemState();
}

class _EditItemState extends State<EditItem> {
  final TextEditingController _amount = TextEditingController();
  late FirebaseFirestore db;
  late User user;

  late DateTime time;
  late double amount;
  String source = '';

  List<ItemType> types = [];
  List<ItemCategory> categories = [];
  List<Capital> capitals = [];
  ItemType type = ItemType();
  Capital payment = Capital();
  ItemCategory category = ItemCategory();
  UserCurrency currency = UserCurrency(currency: "");

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instance;
    getUser();
  }

  Future<void> getUser() async {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        await getValues();
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  Future<void> getValues() async {
    setState(() {
      time = widget.item.time!;
      amount = widget.item.amount!;
      source = widget.item.source!;
      _amount.text = amount.toString();
      currency.currency = widget.item.currency!;
    });
    await fetchTypes();
    type = types.firstWhere((t) => t.id == widget.item.typeID);
    await getCapitals();
    payment = capitals.firstWhere((t) => t.id == widget.item.paymentID);
    await getCats(type.id!);
    category = categories.firstWhere((c) => c.id == widget.item.categoryID);
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
    } catch (e) {
      print("Error retrieving items: $e");
    }
  }

  Future<List<ItemType>> getAllTypes() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot querySnapshot = await db
          .collection("items")
          .doc(user.email)
          .collection("types")
          .get();
      types = querySnapshot.docs.map((docSnapshot) {
        return ItemType.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();
      print("Successfully retrieved ${types.length} types");
    } catch (e) {
      print("Error retrieving items: $e");
      types = [];
    } finally {
      setState(() {
        isLoading = false;
      });
    }
    return types;
  }

  Future<void> fetchTypes() async {
    await getAllTypes();
  }

  Future<void> getCats(String typeID) async {
    categories = [];
    try {
      final typeSnap =
          db.collection("items").doc(user.email).collection("types");
      final catSnap = await typeSnap.doc(typeID).collection("categories").get();
      categories = catSnap.docs.map((thisSnap) {
        return ItemCategory.fromFirestore(
          thisSnap as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();
      print("Categories fetched: $categories");
      setState(() {});
    } catch (e) {
      print("Error retrieving categories: $e");
    }
  }

  void saveChanges() {
    final washingtonRef = db
        .collection("items")
        .doc(user.email)
        .collection("entries")
        .doc(widget.item.id);
    washingtonRef.update({
      "time": time,
      "amount": amount,
      "source": source,
      "typeID": type.id,
      "categoryID": category.id,
      "paymentID": payment.id,
    }).then((value) => print("DocumentSnapshot successfully updated!"),
        onError: (e) => print("Error updating document $e"));
  }

  void deleteEntry() {
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              contentPadding: EdgeInsets.all(20.0),
              children: [
                Text('Are you sure you want to delete this category?'),
                Row(
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel')),
                    TextButton(
                        onPressed: () {
                          db
                              .collection("items")
                              .doc(user.email)
                              .collection("types")
                              .doc(widget.item.id)
                              .delete()
                              .then(
                            (doc) async {
                              const snackBar = SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  dismissDirection: DismissDirection.none,
                                  content: Text('Entry Deleted!'));

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllItems()));
                            },
                            onError: (e) => print("Error updating document $e"),
                          );
                        },
                        child: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ))
                  ],
                ),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    // if (isLoading || types.isEmpty) {
    //   return Scaffold(body: Center(child: CircularProgressIndicator()));
    // }

    final filteredTypes = types.where((t) => t.source == source).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if ((_amount.text.isEmpty ||
                    double.tryParse(_amount.text) == null ||
                    source.isEmpty ||
                    type.id == null ||
                    category.id == null ||
                    capitals.isEmpty) ||
                checkSimilar()) {
              Navigator.pop(context);
            } else {
              saveChanges();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AllItems()),
              );
            }
          },
          icon: Icon((_amount.text.isEmpty ||
                      double.tryParse(_amount.text) == null ||
                      source.isEmpty ||
                      type.id == null ||
                      category.id == null ||
                      capitals.isEmpty) ||
                  checkSimilar()
              ? Icons.arrow_back
              : Icons.check),
        ),
        title: Text('Edit Entry'),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(time.toString().substring(0, 10)),
                  IconButton(
                      onPressed: () {
                        DatePicker.showDatePicker(context,
                            showTitleActions: true,
                            minTime: DateTime(2020, 1, 1),
                            maxTime: DateTime.now(),
                            onChanged: (date) {}, onConfirm: (date) {
                          setState(() {
                            time = date;
                          });
                        }, currentTime: time, locale: LocaleType.en);
                      },
                      icon: Icon(Icons.edit_calendar_outlined))
                ],
              ),
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
                                  currency.currency = thisCurrency.code;
                                });
                              },
                            );
                          },
                          child: Text(currency.currency))),
                  Expanded(
                      flex: 4,
                      child: AmountInput(
                        onChanged: (value) {
                          setState(() {
                            amount = double.tryParse(value) ?? amount;
                          });
                        },
                        amount: _amount,
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceButton('Asset'),
                  _sourceButton('Liability'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceButton('Expense'),
                  _sourceButton('Revenue'),
                ],
              ),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filteredTypes
                        .map((thisType) => _typeButton(thisType))
                        .toList(),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: type.id != null && categories.isNotEmpty
                      ? Row(
                          children:
                              categories.map((cat) => _catButton(cat)).toList(),
                        )
                      : Text('Select a type first or no categories available'),
                ),
              ),

              // row list gen
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(capitals.length,
                    (index) => _capitalButton(capitals[index])),
              ),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton(String thisSource) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor:
                source != thisSource ? Colors.transparent : Colors.green),
        onPressed: () async {
          setState(() {
            source = thisSource;
            type = ItemType();
            category = ItemCategory();
          });
          await fetchTypes();
          if (type.id != null) {
            await getCats(type.id!);
          }
        },
        child: Text(thisSource));
  }

  Widget _typeButton(ItemType thisType) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor:
                type.id != thisType.id ? Colors.transparent : Colors.red),
        onPressed: () async {
          await getCats(thisType.id!);
          setState(() {
            type = thisType;
            category = ItemCategory();
          });
        },
        child: Text(thisType.type!));
  }

  Widget _catButton(ItemCategory thisCat) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor:
                category.id != thisCat.id ? Colors.transparent : Colors.yellow),
        onPressed: () {
          setState(() {
            category = thisCat;
          });
        },
        child: Text(thisCat.category!));
  }

  Widget _capitalButton(Capital thisCapital) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor: payment.id != thisCapital.id
                ? Colors.transparent
                : Colors.pink),
        onPressed: () {
          setState(() {
            payment = thisCapital;
          });
        },
        child: Text(thisCapital.type!));
  }

  bool checkSimilar() {
    return time == widget.item.time &&
        amount == widget.item.amount &&
        source == widget.item.source &&
        type.id == widget.item.typeID &&
        category.id == widget.item.categoryID &&
        payment.id == widget.item.paymentID &&
        currency.currency == widget.item.currency;
  }
}
