import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:aifinance/pages/loadingScereen/LoadingScreen.dart';
import 'package:aifinance/pages/types/EditCat.dart';
import 'package:aifinance/pages/types/EditType.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AllTypes extends StatefulWidget {
  const AllTypes({super.key});

  @override
  State<AllTypes> createState() => _AllTypesState();
}

class _AllTypesState extends State<AllTypes> {
  late FirebaseFirestore db;
  late User user;

  final TextEditingController _newTypeName = TextEditingController();
  final TextEditingController _newCatName = TextEditingController();

  List<ItemType> types = [];
  List<List<ItemCategory>> categories = [[]];
  String source = '';

  bool fav = false;

  bool isLoading = false;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        fetchTypes();
      }
    });
  }

  Future<List<ItemType>> getAllTypes() async {
    int index = 0;
    setState(() {
      isLoading = true;
    });
    try {
      final typeSnap =
          db.collection("items").doc(user.email).collection("types");

      await typeSnap.get().then((querySnapshot) async {
        for (var docSnapshot in querySnapshot.docs) {
          types.add(ItemType.fromFirestore(
            docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
            null,
          ));

          await typeSnap
              .doc(docSnapshot.id)
              .collection("categories")
              .get()
              .then(
            (catSnap) {
              for (var thisSnap in catSnap.docs) {
                categories[index].add(ItemCategory.fromFirestore(
                  thisSnap as DocumentSnapshot<Map<String, dynamic>>,
                  null,
                ));
              }
            },
            onError: (e) => print("Error completing: $e"),
          );
          setState(() {
            categories.add([]);
            index = index + 1;
          });
        }
      });

      print("Successfully retrieved ${types.length} types");
      setState(() {
        isLoading = false;
      });
      return types;
    } catch (e) {
      print("Error retrieving items: $e");
      return [];
    }
  }

  void fetchTypes() async {
    types = await getAllTypes();
  }

  void addType() {
    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => SimpleDialog(
                  contentPadding: EdgeInsets.all(20.0),
                  children: [
                    Text('Add New Type'),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: source != 'Asset'
                                ? Colors.transparent
                                : Colors.green),
                        onPressed: () {
                          setState(() {
                            source = 'Asset';
                          });
                        },
                        child: Text('Asset')),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: source != 'Liability'
                                ? Colors.transparent
                                : Colors.green),
                        onPressed: () {
                          setState(() {
                            source = 'Liability';
                          });
                        },
                        child: Text('Liability')),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: source != 'Expense'
                                ? Colors.transparent
                                : Colors.green),
                        onPressed: () {
                          setState(() {
                            source = 'Expense';
                          });
                        },
                        child: Text('Expense')),
                    TextButton(
                        style: TextButton.styleFrom(
                            backgroundColor: source != 'Revenue'
                                ? Colors.transparent
                                : Colors.green),
                        onPressed: () {
                          setState(() {
                            source = 'Revenue';
                          });
                        },
                        child: Text('Revenue')),
                    TextField(
                      controller: _newTypeName,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel')),
                        TextButton(
                            onPressed: () {
                              if (source != '' && _newTypeName.text != '') {
                                final thisType = ItemType(
                                    source: source,
                                    type: _newTypeName.text.trim());
                                final typeCollection = db
                                    .collection("items")
                                    .doc(user.email)
                                    .collection('types')
                                    .withConverter(
                                      fromFirestore: ItemType.fromFirestore,
                                      toFirestore: (ItemType type, options) =>
                                          type.toFirestore(),
                                    );
                                typeCollection.add(thisType);
                                Navigator.pop(context);
                                fetchTypes();
                              }
                            },
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                  color: source == ''
                                      ? Colors.grey
                                      : Colors.green),
                            )),
                      ],
                    ),
                  ],
                )));
  }

  void addCat(ItemType type) {
    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setState) => SimpleDialog(
                  contentPadding: EdgeInsets.all(20.0),
                  children: [
                    Text('Add New Category Under ${type.type}'),
                    TextField(
                      controller: _newCatName,
                    ),
                    Row(
                      children: [
                        Text('Set to Favorite Category?'),
                        Checkbox(
                            value: fav,
                            onChanged: (value) {
                              setState(() {
                                fav = value!;
                              });
                            })
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
                              if (_newCatName.text != '') {
                                final thisCat = ItemCategory(
                                  category: _newCatName.text.trim(),
                                  fav: fav,
                                );
                                final catCollection = db
                                    .collection("items")
                                    .doc(user.email)
                                    .collection('types')
                                    .doc(type.id)
                                    .collection("categories")
                                    .withConverter(
                                      fromFirestore: ItemCategory.fromFirestore,
                                      toFirestore:
                                          (ItemCategory type, options) =>
                                              type.toFirestore(),
                                    );
                                catCollection.add(thisCat);
                                Navigator.pop(context);
                                fetchTypes();
                              }
                            },
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                  color: _newCatName.text != ''
                                      ? Colors.grey
                                      : Colors.green),
                            )),
                      ],
                    ),
                  ],
                )));
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
              "assets/images/icons/types.png",
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
            Text(' All Types'),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {
                addType();
              },
              icon: Icon(Icons.add))
        ],
      ),
      body: isLoading
          ? LoadingScreen()
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: List.generate(
                          types.length,
                          (index) => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                // edit type name
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            EditType(
                                                              type:
                                                                  types[index],
                                                            )));
                                              },
                                              icon: Icon(Icons.edit)),
                                          Text(
                                            types[index].type!,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            types[index].source!,
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: types[index].source ==
                                                        "Expense"
                                                    ? Colors.red
                                                    : Colors.green),
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                // add new cat
                                                addCat(types[index]);
                                              },
                                              icon: Icon(Icons.add)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: List.generate(
                                        categories[index].length,
                                        (catIndex) => GestureDetector(
                                              onTap: () => Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditCat(
                                                              typeID:
                                                                  types[index]
                                                                      .id!,
                                                              category: categories[
                                                                      index]
                                                                  [catIndex]))),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    categories[index][catIndex]
                                                            .fav
                                                        ? Icons.star
                                                        : null,
                                                    color: Colors.amber,
                                                  ),
                                                  Text(categories[index]
                                                          [catIndex]
                                                      .category!),
                                                ],
                                              ),
                                            )),
                                  ),
                                ],
                              )),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
