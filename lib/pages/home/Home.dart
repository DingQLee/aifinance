import 'package:aifinance/database/models.dart';
import 'package:aifinance/game/Game.dart';
import 'package:aifinance/pages/AllCapitals/AllCapitals.dart';
import 'package:aifinance/pages/allItems/AllItems.dart';
import 'package:aifinance/pages/auth/Auth.dart';
import 'package:aifinance/pages/currency/CurrencySetting.dart';
import 'package:aifinance/pages/loadingScereen/LoadingScreen.dart';
import 'package:aifinance/pages/report/Report.dart';
import 'package:aifinance/pages/types/AllTypes.dart';
import 'package:aifinance/widgets/AmountInput.dart';
import 'package:aifinance/widgets/SquareButton.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavCat {
  String source;
  ItemType type;
  ItemCategory category;
  FavCat({
    required this.source,
    required this.type,
    required this.category,
  });
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late FirebaseFirestore db;
  late User user;

  final TextEditingController _amount = TextEditingController();
  ItemType type = ItemType();
  String source = 'Expense';
  Capital payment = Capital(type: "");
  ItemCategory category = ItemCategory();
  UserCurrency currency = UserCurrency(currency: "");

  List<ItemType> types = [];
  List<ItemCategory> categories = [];
  List<Capital> capitals = [];
  List<FavCat> favCat = [];
  int selectedTypeIndex = -1;

  bool isLoading = true;

  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    db = FirebaseFirestore.instance;
    getUser(); // Load user and initial data
  }

  Future<void> getUser() async {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        await initializeData(); // Fetch all initial data
      }
    });
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true; // Set loading state
    });
    await fetchTypes(); // Fetch types and favorite categories
    await getCapitals(); // Fetch transfers
    await getCurrency();
    setState(() {
      isLoading = false; // Data is loaded, update UI
    });
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

  void logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Auth()),
      );
    } catch (e) {
      print("Error logging out: $e");
    }
  }

  void addItem() async {
    double enteredAmount = double.parse(_amount.text);

    if (payment.amount != null &&
        enteredAmount > payment.amount! &&
        source == 'Expense' &&
        payment.source == 'Asset') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Insufficient amount! You cannot add more than ${payment.amount}.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (payment.currency != currency.currency) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Currency does not match! You may add a new capital for that currency.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (payment.id != '' &&
        type.type != '' &&
        category.category != '' &&
        source != '' &&
        _amount.text != '') {
      final item = Item(
        currency: currency.currency,
        amount: double.parse(_amount.text),
        typeID: type.id,
        source: source,
        categoryID: category.id,
        time: DateTime.now(),
        paymentID: payment.id,
      );

      setState(() {
        isLoading = true;
      });

      final entriesRef = db
          .collection("items")
          .doc(user.email)
          .collection('entries')
          .withConverter(
            fromFirestore: Item.fromFirestore,
            toFirestore: (Item item, options) => item.toFirestore(),
          );
      await entriesRef.add(item);

      final capitalRef = db
          .collection("items")
          .doc(user.email)
          .collection('capitals')
          .doc(payment.id);
      if (source == 'Expense' && payment.source == "Asset" ||
          source == 'Revenue' && payment.source == "Liability") {
        await capitalRef
            .update({"amount": payment.amount! - double.parse(_amount.text)});
      } else {
        await capitalRef
            .update({"amount": payment.amount! + double.parse(_amount.text)});
      }
      setState(() {
        source = '';
        payment = Capital(type: "");
        type = ItemType();
        category = ItemCategory();
        selectedTypeIndex = -1;
        _amount.text = '';
      });
      initializeData();
      const snackBar = SnackBar(
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.none,
          content: Text('Entry Saved!'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getAllTypes() async {
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
    }
  }

  Future<void> fetchTypes() async {
    await getAllTypes();
    await getFavCats();
  }

  Future<void> getCats(String typeID) async {
    categories = [];
    final typeSnap = db.collection("items").doc(user.email).collection("types");
    await typeSnap.doc(typeID).collection("categories").get().then(
      (catSnap) {
        for (var thisSnap in catSnap.docs) {
          categories.add(ItemCategory.fromFirestore(
            thisSnap as DocumentSnapshot<Map<String, dynamic>>,
            null,
          ));
        }
        setState(() {});
      },
      onError: (e) => print("Error completing: $e"),
    );
  }

  Future<void> getFavCats() async {
    favCat = [];
    final typeSnap = db.collection("items").doc(user.email).collection("types");

    for (var thisType in types) {
      await typeSnap.doc(thisType.id).collection("categories").get().then(
        (catSnap) {
          for (var thisSnap in catSnap.docs) {
            final cat = ItemCategory.fromFirestore(
              thisSnap as DocumentSnapshot<Map<String, dynamic>>,
              null,
            );
            if (cat.fav) {
              favCat.add(FavCat(
                source: thisType.source ?? '',
                type: thisType,
                category: cat,
              ));
            }
          }
        },
        onError: (e) => print("Error completing: $e"),
      );
    }
    print("Favorite categories fetched: ${favCat.length}");
    setState(() {});
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: LoadingScreen(),
      );
    }

    final filteredTypes = types.where((t) => t.source == source).toList();

    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.all(20.0),
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Digify'),
            ),
            SquareButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllTypes())),
                child: Text('All Types')),
            SquareButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllItems())),
                child: Text('All Items')),
            SquareButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AllCapitals())),
                child: Text('Assets and Liabilities')),
            SquareButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Report())),
                child: Text('Report')),
            SquareButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => CurrencySetting())),
                child: Text('Currency')),
            SquareButton(onPressed: logout, child: Text('Logout')),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  SquareButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => FightingGameScreen())),
                      child: Text('Game')),
                ],
              ),
              Text('Quick Entry'),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: favCat.map((cat) => _favCatButton(cat)).toList(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sourceButton('Expense'),
                  _sourceButton('Revenue'),
                ],
              ),
              Text('Fav types and categories'),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filteredTypes
                        .asMap()
                        .entries
                        .map((entry) => _typeButton(
                            entry.value.id!, entry.value, entry.key))
                        .toList(),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories
                        .map((cat) => _catButtonForItemCategory(cat))
                        .toList(),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: capitals
                        .map((capital) => _capitalButton(capital))
                        .toList(),
                  ),
                ),
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
                      child: Text(currency.currency),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: AmountInput(
                        onChanged: () {
                          setState(() {});
                        },
                        amount: _amount),
                  ),
                  Expanded(
                    flex: 1,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: payment.type != '' &&
                                type.type != '' &&
                                category.category != '' &&
                                source != '' &&
                                _amount.text != ''
                            ? Colors.blue // Enabled state color
                            : Colors.grey
                                .withOpacity(0.3), // Disabled state color
                        foregroundColor: Colors.white, // Text/icon color
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: (payment.type != '' &&
                              type.type != '' &&
                              category.category != '' &&
                              source != '' &&
                              _amount.text != '')
                          ? addItem
                          : null,
                      child: const Text('ADD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton(String thisSource) {
    return TextButton(
        style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 4, color: Colors.amber),
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor:
                source != thisSource ? Colors.transparent : Colors.green,
            foregroundColor: Colors.white),
        onPressed: () {
          setState(() {
            source = thisSource;
            selectedTypeIndex = -1; // Reset when source changes
            type = ItemType();
            category = ItemCategory();
          });
        },
        child: Text(thisSource));
  }

  Widget _typeButton(String typeID, ItemType thisType, int index) {
    return TextButton(
        style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 4, color: Colors.amber),
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: type != thisType ? Colors.transparent : Colors.red,
            foregroundColor: Colors.white),
        onPressed: () async {
          await getCats(typeID);
          setState(() {
            type = thisType;
            selectedTypeIndex = index;
          });
        },
        child: Text(thisType.type!));
  }

  Widget _favCatButton(FavCat thisCat) {
    return TextButton(
        style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 4, color: Colors.amber),
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: category.category != thisCat.category.category
                ? Colors.transparent
                : Colors.yellow,
            foregroundColor: Colors.white),
        onPressed: () async {
          await getCats(thisCat.type.id!);
          setState(() {
            source = thisCat.source;
            type = thisCat.type;
            category = thisCat.category;
          });
        },
        child: Row(
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
            ),
            Text(
                "${thisCat.source} - ${thisCat.type.type} - ${thisCat.category.category}"),
          ],
        ));
  }

  Widget _catButtonForItemCategory(ItemCategory thisCat) {
    return TextButton(
        style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 4, color: Colors.amber),
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: category.category != thisCat.category
                ? Colors.transparent
                : Colors.blue,
            foregroundColor: Colors.white),
        onPressed: () {
          setState(() {
            category = thisCat;
          });
        },
        child: Row(
          children: [
            Visibility(
              visible: thisCat.fav,
              child: Icon(
                Icons.star,
                color: Colors.amber,
              ),
            ),
            Text(thisCat.category!),
          ],
        ));
  }

  Widget _capitalButton(Capital thisCapital) {
    return TextButton(
        style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              side: BorderSide(width: 4, color: Colors.amber),
              borderRadius: BorderRadius.circular(0),
            ),
            backgroundColor: payment.type != thisCapital.type
                ? Colors.transparent
                : Colors.pink,
            foregroundColor: Colors.white),
        onPressed: () {
          setState(() {
            payment = thisCapital;
          });
        },
        child: Row(
          children: [
            Visibility(
              visible: thisCapital.fav,
              child: Icon(
                Icons.star,
                color: Colors.amber,
              ),
            ),
            Visibility(
              visible: currency.currency != thisCapital.currency,
              child: Icon(
                Icons.warning,
                color: Colors.red,
              ),
            ),
            Text(
                "${thisCapital.type!} \$${thisCapital.amount!.toStringAsFixed(2)}"),
          ],
        ));
  }
}
