import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/types/AllTypes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditCat extends StatefulWidget {
  final String typeID;
  final ItemCategory category;
  const EditCat({
    super.key,
    required this.typeID,
    required this.category,
  });

  @override
  State<EditCat> createState() => _EditCatState();
}

class _EditCatState extends State<EditCat> {
  late FirebaseFirestore db;
  late User user;

  final TextEditingController _newCatName = TextEditingController();

  String oldCat = '';
  bool fav = false;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
      }
    });
  }

  bool checkSimilar() {
    return _newCatName.text.trim() == widget.category.category &&
        fav == widget.category.fav;
  }

  void saveChanges() async {
    final ref = db
        .collection("items")
        .doc(user.email)
        .collection("types")
        .doc(widget.typeID)
        .collection("categories")
        .doc(widget.category.id);
    await ref.update({
      "category": _newCatName.text.trim(),
      "fav": fav,
    }).then((value) => print("DocumentSnapshot successfully updated!"),
        onError: (e) => print("Error updating document $e"));
  }

  void deleteCat() {
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
                              .doc(widget.typeID)
                              .collection("categories")
                              .doc(widget.category.id)
                              .delete()
                              .then(
                            (doc) async {
                              const snackBar = SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  dismissDirection: DismissDirection.none,
                                  content: Text('Category Deleted!'));

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllTypes()));
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
  void initState() {
    oldCat = widget.category.category!;
    _newCatName.text = widget.category.category!;
    fav = widget.category.fav;
    getUser();
    db = FirebaseFirestore.instance;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              if (checkSimilar()) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllTypes()));
              } else {
                saveChanges();

                const snackBar = SnackBar(
                    behavior: SnackBarBehavior.floating,
                    dismissDirection: DismissDirection.none,
                    content: Text('Changes Saved!'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllTypes()));
              }
            },
            icon: Icon(checkSimilar() ? Icons.arrow_back : Icons.check)),
        title: Text(widget.category.category!),
        actions: [
          IconButton(
              onPressed: () {
                deleteCat();
              },
              icon: Icon(Icons.delete)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text('Edit Category Name:'),
              TextField(
                onChanged: (value) {
                  setState(() {});
                },
                controller: _newCatName,
              ),
              Checkbox(
                value: fav,
                onChanged: (value) {
                  setState(() {
                    fav = value!;
                  });
                },
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
}
