import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/allItems/EditItem.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:aifinance/pages/loadingScereen/LoadingScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart';

class AllItems extends StatefulWidget {
  const AllItems({super.key});

  @override
  State<AllItems> createState() => _AllItemsState();
}

class _AllItemsState extends State<AllItems> {
  late FirebaseFirestore db;
  late User user;
  List<Item> itemsList = [];
  Map<String, ItemType> types = {};
  List<ItemCategory> categories = [];
  Map<String, Capital> capitals = {};
  String source = '';

  bool isLoading = false;
  DateTime startingDate = DateTime.now().subtract(Duration(days: 1));
  DateTime endingDate = DateTime.now();

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        fetchItems();
        fetchTypes();
        fetchCapital();
      }
    });
  }

  void fetchCapital() async {
    await getCapitals();
  }

  Future<void> getCapitals() async {
    try {
      QuerySnapshot querySnapshot = await db
          .collection("items")
          .doc(user.email)
          .collection("capitals")
          .get();

      Map<String, Capital> capitalMap = {};
      for (var docSnapshot in querySnapshot.docs) {
        final itemCap = Capital.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
        capitalMap[docSnapshot.id] = itemCap; // Use document ID as the key
      }

      setState(() {
        capitals = capitalMap;
      });
    } catch (e) {
      print("Error retrieving items: $e");
    }
  }

  Future<List<Item>> getItemsByDateRange(
      DateTime startDate, DateTime endDate) async {
    setState(() {
      isLoading = true;
    });

    try {
      final startTimestamp = Timestamp.fromDate(startDate.toUtc());
      final endTimestamp =
          Timestamp.fromDate(endDate.add(const Duration(days: 1)).toUtc());

      QuerySnapshot querySnapshot = await db
          .collection("items")
          .doc(user.email)
          .collection("entries")
          .where("time", isGreaterThanOrEqualTo: startTimestamp)
          .where("time", isLessThanOrEqualTo: endTimestamp)
          .get();

      List<Item> items = querySnapshot.docs.map((docSnapshot) {
        return Item.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();

      print(
          "Successfully retrieved ${items.length} items from $startDate to $endDate");
      setState(() {
        isLoading = false;
      });
      return items;
    } catch (e) {
      print("Error retrieving items: $e");
      setState(() {
        isLoading = false;
      });
      return [];
    }
  }

  Future<void> fetchItems() async {
    itemsList = await getItemsByDateRange(startingDate, endingDate);
  }

  Future<void> getAllTypes() async {
    try {
      QuerySnapshot querySnapshot = await db
          .collection("items")
          .doc(user.email)
          .collection("types")
          .get();

      Map<String, ItemType> typeMap = {};
      for (var docSnapshot in querySnapshot.docs) {
        final itemType = ItemType.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
        typeMap[docSnapshot.id] = itemType; // Use document ID as the key
      }

      setState(() {
        types = typeMap;
      });

      print("Successfully retrieved ${types.length} types");
    } catch (e) {
      print("Error retrieving items: $e");
    }
  }

  void fetchTypes() async {
    await getAllTypes();
  }

  void selectSource(String thisSource) {
    if (source == thisSource) {
      setState(() {
        source = '';
      });
    } else {
      setState(() {
        source = thisSource;
      });
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
      body: Center(
        child: isLoading
            ? LoadingScreen()
            : CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    leading: IconButton(
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Home())),
                        icon: Icon(Icons.arrow_back)),
                    title: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _sourceButton("Expense"),
                            _sourceButton("Revenue"),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                          onPressed: () {
                            DatePicker.showDatePicker(context,
                                showTitleActions: true,
                                minTime: DateTime(2020, 1, 1),
                                maxTime: endingDate,
                                onChanged: (date) {}, onConfirm: (date) async {
                              setState(() {
                                startingDate = date;
                              });
                              itemsList = await getItemsByDateRange(
                                  startingDate, endingDate);
                            },
                                currentTime: startingDate,
                                locale: LocaleType.en);
                          },
                          icon: Icon(Icons.calendar_month_outlined)),
                      Text("${startingDate.toLocal()}".split(' ')[0]),
                      Text(" to "),
                      Text("${endingDate.toLocal()}".split(' ')[0]),
                      IconButton(
                          onPressed: () {
                            DatePicker.showDatePicker(context,
                                showTitleActions: true,
                                minTime: startingDate,
                                maxTime: DateTime.now(),
                                onChanged: (date) {}, onConfirm: (date) async {
                              setState(() {
                                endingDate = date;
                              });
                              itemsList = await getItemsByDateRange(
                                  startingDate, endingDate);
                            }, currentTime: endingDate, locale: LocaleType.en);
                          },
                          icon: Icon(Icons.calendar_today)),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: itemsList.isEmpty
                        ? Center(child: Text('No Items Yet'))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(
                                itemsList.length,
                                (index) => Visibility(
                                      visible:
                                          source == itemsList[index].source ||
                                              source == '',
                                      child: GestureDetector(
                                        onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => EditItem(
                                                      item: itemsList[index],
                                                    ))),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(itemsList[index]
                                                          .currency!),
                                                      Text(
                                                          '\$${itemsList[index].amount}'),
                                                    ],
                                                  ),
                                                  Text(itemsList[index]
                                                      .time
                                                      .toString()
                                                      .substring(0, 10)),
                                                ],
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Text(capitals[itemsList[index]
                                                          .paymentID!]!
                                                      .type!),
                                                  Text(types[itemsList[index]
                                                          .typeID!]!
                                                      .type!),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sourceButton(String thisSource) {
    return GestureDetector(
        onTap: () {
          selectSource(thisSource);
        },
        child: Text(
          thisSource,
          style: TextStyle(
              color: source == thisSource ? Colors.green : Colors.white),
        ));
  }
}
