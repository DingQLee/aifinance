import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/types/AllTypes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditType extends StatefulWidget {
  final ItemType type;
  const EditType({
    super.key,
    required this.type,
  });

  @override
  State<EditType> createState() => _EditTypeState();
}

class _EditTypeState extends State<EditType> {
  late FirebaseFirestore db;
  late User user;

  final TextEditingController _newTypeName = TextEditingController();
  String source = '';

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
      }
    });
  }

  bool checkSimilar() {
    if (source != widget.type.source || _newTypeName.text != widget.type.type) {
      return false;
    }
    return true;
  }

  void saveChanges() {
    final washingtonRef = db
        .collection("items")
        .doc(user.email)
        .collection("types")
        .doc(widget.type.id);
    washingtonRef.update({
      "type": _newTypeName.text.trim(),
      "source": source,
    }).then((value) => print("DocumentSnapshot successfully updated!"),
        onError: (e) => print("Error updating document $e"));
  }

  void deleteType() {
    showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              contentPadding: EdgeInsets.all(20.0),
              children: [
                Text(
                    'Are you sure you want to delete this type? This will delete all categories under this type.'),
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
                              .doc(widget.type.id)
                              .delete()
                              .then(
                            (doc) async {
                              const snackBar = SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  dismissDirection: DismissDirection.none,
                                  content: Text('Type Deleted!'));

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(snackBar);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllTypes()));
                            },
                            onError: (e) => print("Error deleting type $e"),
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
    _newTypeName.text = widget.type.type!;
    source = widget.type.source!;
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
        title: Text(widget.type.type!),
        actions: [
          IconButton(
              onPressed: () {
                deleteType();
              },
              icon: Icon(Icons.delete)),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            // edit name, edit source
            Text('Item Type:'),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: TextField(
                controller: _newTypeName,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
            Text('Item Type:'),
            Text(widget.type.source!),
            Text('Select New Item Type:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _sourceButton('Asset'),
                _sourceButton('Liability'),
                _sourceButton('Expense'),
                _sourceButton('Revenue'),
              ],
            ),
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: List.generate(
            //       widget.type.categories.length,
            //       (index) => Row(
            //             children: [
            //               IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
            //               Text(
            //                 widget.type.categories[index].category!,
            //                 style: TextStyle(
            //                     color: widget.type.categories[index].category ==
            //                             oldCategories[index].category
            //                         ? Colors.white
            //                         : Colors.green),
            //               ),
            //             ],
            //           )),
            // )
          ],
        ),
      ),
    );
  }

  Widget _sourceButton(String thisSource) {
    return TextButton(
        style: TextButton.styleFrom(
            backgroundColor:
                source != thisSource ? Colors.transparent : Colors.green),
        onPressed: () {
          setState(() {
            source = thisSource;
          });
        },
        child: Text(thisSource));
  }
}
