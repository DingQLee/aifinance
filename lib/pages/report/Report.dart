import 'package:aifinance/database/models.dart';
import 'package:aifinance/pages/home/Home.dart';
import 'package:aifinance/pages/report/BarChart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TotalAmount {
  bool isExpense;
  double amount;
  String currency;

  TotalAmount({
    required this.isExpense,
    required this.amount,
    required this.currency,
  });
}

class Report extends StatefulWidget {
  const Report({super.key});

  @override
  State<Report> createState() => _ReportState();
}

class _ReportState extends State<Report> {
  int _selectedIndex = 0;

  late FirebaseFirestore db;
  late User user;

  List<Item> itemsList = [];
  List<ItemType> types = [];

  List<TotalAmount> totalExpense = [];
  List<TotalAmount> totalRevenue = [];
  Map<String, List<TotalAmount>> monthlyExpense = {};
  Map<String, List<TotalAmount>> monthlyRevenue = {};
  Map<String, double> fourMonthExpense = {};
  Map<String, double> fourMonthRevenue = {};
  Map<String, double> dailyExpense = {};
  Map<String, double> dailyRevenue = {};

  Map<String, List<TotalAmount>> totalExpenseByType = {};
  Map<String, List<TotalAmount>> totalRevenueByType = {};
  Map<String, Map<String, List<TotalAmount>>> monthlyExpenseByType = {};
  Map<String, Map<String, List<TotalAmount>>> monthlyRevenueByType = {};
  Map<String, Map<String, double>> fourMonthExpenseByType = {};
  Map<String, Map<String, double>> fourMonthRevenueByType = {};
  Map<String, Map<String, double>> dailyExpenseByType = {};
  Map<String, Map<String, double>> dailyRevenueByType = {};

  bool isLoading = false;

  void getUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? _user) async {
      if (_user != null) {
        user = _user;
        await getAllTypes();
        fetchItems();
      }
    });
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

  String getTypeName(String typeID) {
    return types
            .firstWhere(
              (type) => type.id == typeID,
              orElse: () => ItemType(id: typeID, type: 'Unknown', source: null),
            )
            .type ??
        'Unknown';
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    try {
      QuerySnapshot querySnapshot = await db
          .collection("items")
          .doc(user.email)
          .collection("entries")
          .get();

      itemsList = querySnapshot.docs.map((docSnapshot) {
        return Item.fromFirestore(
          docSnapshot as DocumentSnapshot<Map<String, dynamic>>,
          null,
        );
      }).toList();

      totalExpense.clear();
      totalRevenue.clear();
      monthlyExpense.clear();
      monthlyRevenue.clear();
      fourMonthExpense.clear();
      fourMonthRevenue.clear();
      dailyExpense.clear();
      dailyRevenue.clear();
      totalExpenseByType.clear();
      totalRevenueByType.clear();
      monthlyExpenseByType.clear();
      monthlyRevenueByType.clear();
      fourMonthExpenseByType.clear();
      fourMonthRevenueByType.clear();
      dailyExpenseByType.clear();
      dailyRevenueByType.clear();

      DateTime now = DateTime.now();
      String currentMonthKey = "${now.year}-${now.month}";

      for (var item in itemsList) {
        String typeName = getTypeName(item.typeID!);
        if (item.source == 'Expense') {
          _updateTotalList(totalExpense, item.amount!, item.currency!, true);
          _updateTotalList(totalExpenseByType[typeName] ??= [], item.amount!,
              item.currency!, true);
          _updateMonthlyAndFourMonth(item, true, typeName);

          String dayKey =
              "${item.time!.year}-${item.time!.month}-${item.time!.day}";
          if (item.time!.isAfter(DateTime(now.year, now.month, 1))) {
            if (!dailyExpense.containsKey(dayKey)) dailyExpense[dayKey] = 0;
            dailyExpense[dayKey] = dailyExpense[dayKey]! + item.amount!;
            if (!dailyExpenseByType.containsKey(dayKey))
              dailyExpenseByType[dayKey] = {};
            if (!dailyExpenseByType[dayKey]!.containsKey(typeName))
              dailyExpenseByType[dayKey]![typeName] = 0;
            dailyExpenseByType[dayKey]![typeName] =
                dailyExpenseByType[dayKey]![typeName]! + item.amount!;
          }
        } else {
          _updateTotalList(totalRevenue, item.amount!, item.currency!, false);
          _updateTotalList(totalRevenueByType[typeName] ??= [], item.amount!,
              item.currency!, false);
          _updateMonthlyAndFourMonth(item, false, typeName);

          String dayKey =
              "${item.time!.year}-${item.time!.month}-${item.time!.day}";
          if (item.time!.isAfter(DateTime(now.year, now.month, 1))) {
            if (!dailyRevenue.containsKey(dayKey)) dailyRevenue[dayKey] = 0;
            dailyRevenue[dayKey] = dailyRevenue[dayKey]! + item.amount!;
            if (!dailyRevenueByType.containsKey(dayKey))
              dailyRevenueByType[dayKey] = {};
            if (!dailyRevenueByType[dayKey]!.containsKey(typeName))
              dailyRevenueByType[dayKey]![typeName] = 0;
            dailyRevenueByType[dayKey]![typeName] =
                dailyRevenueByType[dayKey]![typeName]! + item.amount!;
          }
        }
      }

      print("Successfully retrieved ${itemsList.length} items.");
    } catch (e) {
      print("Error retrieving items: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateMonthlyAndFourMonth(Item item, bool isExpense, String typeName) {
    String monthKey = "${item.time!.year}-${item.time!.month}";
    String fourMonthKey =
        "${item.time!.year}-${((item.time!.month - 1) ~/ 4) + 1}";

    if (isExpense) {
      if (!monthlyExpense.containsKey(monthKey)) monthlyExpense[monthKey] = [];
      _updateTotalList(
          monthlyExpense[monthKey]!, item.amount!, item.currency!, true);
      if (!monthlyExpenseByType.containsKey(monthKey))
        monthlyExpenseByType[monthKey] = {};
      if (!monthlyExpenseByType[monthKey]!.containsKey(typeName))
        monthlyExpenseByType[monthKey]![typeName] = [];
      _updateTotalList(monthlyExpenseByType[monthKey]![typeName]!, item.amount!,
          item.currency!, true);

      if (!fourMonthExpense.containsKey(fourMonthKey))
        fourMonthExpense[fourMonthKey] = 0;
      fourMonthExpense[fourMonthKey] =
          fourMonthExpense[fourMonthKey]! + item.amount!;
      if (!fourMonthExpenseByType.containsKey(fourMonthKey))
        fourMonthExpenseByType[fourMonthKey] = {};
      if (!fourMonthExpenseByType[fourMonthKey]!.containsKey(typeName))
        fourMonthExpenseByType[fourMonthKey]![typeName] = 0;
      fourMonthExpenseByType[fourMonthKey]![typeName] =
          fourMonthExpenseByType[fourMonthKey]![typeName]! + item.amount!;
    } else {
      if (!monthlyRevenue.containsKey(monthKey)) monthlyRevenue[monthKey] = [];
      _updateTotalList(
          monthlyRevenue[monthKey]!, item.amount!, item.currency!, false);
      if (!monthlyRevenueByType.containsKey(monthKey))
        monthlyRevenueByType[monthKey] = {};
      if (!monthlyRevenueByType[monthKey]!.containsKey(typeName))
        monthlyRevenueByType[monthKey]![typeName] = [];
      _updateTotalList(monthlyRevenueByType[monthKey]![typeName]!, item.amount!,
          item.currency!, false);

      if (!fourMonthRevenue.containsKey(fourMonthKey))
        fourMonthRevenue[fourMonthKey] = 0;
      fourMonthRevenue[fourMonthKey] =
          fourMonthRevenue[fourMonthKey]! + item.amount!;
      if (!fourMonthRevenueByType.containsKey(fourMonthKey))
        fourMonthRevenueByType[fourMonthKey] = {};
      if (!fourMonthRevenueByType[fourMonthKey]!.containsKey(typeName))
        fourMonthRevenueByType[fourMonthKey]![typeName] = 0;
      fourMonthRevenueByType[fourMonthKey]![typeName] =
          fourMonthRevenueByType[fourMonthKey]![typeName]! + item.amount!;
    }
  }

  void _updateTotalList(List<TotalAmount> totalList, double amount,
      String currency, bool isExpense) {
    final existingEntry = totalList.firstWhere(
      (total) => total.currency == currency,
      orElse: () =>
          TotalAmount(isExpense: isExpense, amount: 0, currency: currency),
    );

    if (existingEntry.amount > 0) {
      existingEntry.amount += amount;
    } else {
      totalList.add(TotalAmount(
          isExpense: isExpense, amount: amount, currency: currency));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
    DateTime now = DateTime.now();
    String currentMonth = "${now.year}-${now.month}";
    DateTime oneYearAgo = now.subtract(Duration(days: 365));

    Map<String, List<TotalAmount>> pastYearExpenses = Map.fromEntries(
      monthlyExpense.entries.where((entry) {
        List<String> parts = entry.key.split('-');
        int year = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        DateTime monthDate = DateTime(year, month);
        return monthDate.isAfter(oneYearAgo) ||
            monthDate.isAtSameMomentAs(oneYearAgo);
      }),
    );

    Map<String, List<TotalAmount>> pastYearRevenue = Map.fromEntries(
      monthlyRevenue.entries.where((entry) {
        List<String> parts = entry.key.split('-');
        int year = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        DateTime monthDate = DateTime(year, month);
        return monthDate.isAfter(oneYearAgo) ||
            monthDate.isAtSameMomentAs(oneYearAgo);
      }),
    );

    Map<String, Map<String, List<TotalAmount>>> pastYearExpensesByType =
        Map.fromEntries(
      monthlyExpenseByType.entries.where((entry) {
        List<String> parts = entry.key.split('-');
        int year = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        DateTime monthDate = DateTime(year, month);
        return monthDate.isAfter(oneYearAgo) ||
            monthDate.isAtSameMomentAs(oneYearAgo);
      }),
    );

    Map<String, Map<String, List<TotalAmount>>> pastYearRevenueByType =
        Map.fromEntries(
      monthlyRevenueByType.entries.where((entry) {
        List<String> parts = entry.key.split('-');
        int year = int.parse(parts[0]);
        int month = int.parse(parts[1]);
        DateTime monthDate = DateTime(year, month);
        return monthDate.isAfter(oneYearAgo) ||
            monthDate.isAtSameMomentAs(oneYearAgo);
      }),
    );

    // Convert monthlyExpenseByType to a simpler Map<String, Map<String, double>> for BarChart
    Map<String, Map<String, double>> monthlyExpenseByTypeSimple = {};
    pastYearExpensesByType.forEach((month, types) {
      monthlyExpenseByTypeSimple[month] = {};
      types.forEach((type, totals) {
        double totalAmount = totals.fold(0, (sum, t) => sum + t.amount);
        monthlyExpenseByTypeSimple[month]![type] = totalAmount;
      });
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          ),
          icon: Icon(Icons.arrow_back),
        ),
        title: Text('Report'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood_rounded), label: 'Monthly'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph_rounded), label: 'Yearly'),
          BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom), label: 'All Time'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : <Widget>[
              // Monthly Report
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Monthly Report - $currentMonth',
                            style: TextStyle(fontSize: 20))),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Daily Expenses')),
                    if (dailyExpense.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No expenses this month'))
                    else
                      ...dailyExpense.entries.map((entry) {
                        String day = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Day: ${day.split('-')[2]}'),
                              Text(
                                  'Expense: ${entry.value.toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Expenses by Type')),
                    if (dailyExpenseByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No expenses by type this month'))
                    else
                      ...dailyExpenseByType.entries.map((entry) {
                        String day = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day: ${day.split('-')[2]}'),
                              ...entry.value.entries.map((typeEntry) => Padding(
                                    padding: EdgeInsets.only(left: 16),
                                    child: Text(
                                        '${typeEntry.key}: ${typeEntry.value.toStringAsFixed(2)}'),
                                  )),
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 16),
                    BarChart(
                      data: dailyExpenseByType,
                      title: 'Daily Expenses Bar Chart',
                    ),
                    SizedBox(height: 16),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Daily Revenue')),
                    if (dailyRevenue.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No revenue this month'))
                    else
                      ...dailyRevenue.entries.map((entry) {
                        String day = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Day: ${day.split('-')[2]}'),
                              Text(
                                  'Revenue: ${entry.value.toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Revenue by Type')),
                    if (dailyRevenueByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No revenue by type this month'))
                    else
                      ...dailyRevenueByType.entries.map((entry) {
                        String day = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Day: ${day.split('-')[2]}'),
                              ...entry.value.entries.map((typeEntry) => Padding(
                                    padding: EdgeInsets.only(left: 16),
                                    child: Text(
                                        '${typeEntry.key}: ${typeEntry.value.toStringAsFixed(2)}'),
                                  )),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              // Yearly Report
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Yearly Report',
                            style: TextStyle(fontSize: 20))),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Yearly Totals')),
                    ...totalExpense.map((total) => Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text(
                              'Total Expenses - ${total.currency}: ${total.amount.toStringAsFixed(2)}'),
                        )),
                    ...totalRevenue.map((total) => Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text(
                              'Total Revenue - ${total.currency}: ${total.amount.toStringAsFixed(2)}'),
                        )),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Totals by Type')),
                    if (totalExpenseByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No expenses by type'))
                    else
                      ...totalExpenseByType.entries.map((entry) => Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: entry.value
                                  .map((total) => Text(
                                      'Expense ${entry.key} (${total.currency}): ${total.amount.toStringAsFixed(2)}'))
                                  .toList(),
                            ),
                          )),
                    if (totalRevenueByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No revenue by type'))
                    else
                      ...totalRevenueByType.entries.map((entry) => Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: entry.value
                                  .map((total) => Text(
                                      'Revenue ${entry.key} (${total.currency}): ${total.amount.toStringAsFixed(2)}'))
                                  .toList(),
                            ),
                          )),
                    SizedBox(height: 16),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Monthly Breakdown (Past 365 Days)')),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Monthly Expenses')),
                    if (pastYearExpenses.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No expenses in the past 365 days'))
                    else
                      ...pastYearExpenses.entries.map((entry) {
                        String month = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entry.value
                                .map((total) => Text(
                                    'Month $month (${total.currency}): ${total.amount.toStringAsFixed(2)}'))
                                .toList(),
                          ),
                        );
                      }),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Monthly Expenses by Type')),
                    if (pastYearExpensesByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child:
                              Text('No expenses by type in the past 365 days'))
                    else
                      ...pastYearExpensesByType.entries.map((entry) {
                        String month = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Month $month'),
                              ...entry.value.entries.map((typeEntry) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: typeEntry.value
                                        .map((total) => Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16),
                                              child: Text(
                                                  '${typeEntry.key} (${total.currency}): ${total.amount.toStringAsFixed(2)}'),
                                            ))
                                        .toList(),
                                  )),
                            ],
                          ),
                        );
                      }),
                    SizedBox(height: 16),
                    BarChart(
                      data: monthlyExpenseByTypeSimple,
                      title: 'Monthly Expenses Bar Chart (Past 365 Days)',
                    ),
                    SizedBox(height: 16),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Monthly Revenue')),
                    if (pastYearRevenue.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No revenue in the past 365 days'))
                    else
                      ...pastYearRevenue.entries.map((entry) {
                        String month = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entry.value
                                .map((total) => Text(
                                    'Month $month (${total.currency}): ${total.amount.toStringAsFixed(2)}'))
                                .toList(),
                          ),
                        );
                      }),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Monthly Revenue by Type')),
                    if (pastYearRevenueByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child:
                              Text('No revenue by type in the past 365 days'))
                    else
                      ...pastYearRevenueByType.entries.map((entry) {
                        String month = entry.key;
                        return Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Month $month'),
                              ...entry.value.entries.map((typeEntry) => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: typeEntry.value
                                        .map((total) => Padding(
                                              padding:
                                                  EdgeInsets.only(left: 16),
                                              child: Text(
                                                  '${typeEntry.key} (${total.currency}): ${total.amount.toStringAsFixed(2)}'),
                                            ))
                                        .toList(),
                                  )),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              // Four-Month Report
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Four-Month Report',
                            style: TextStyle(fontSize: 20))),
                    ...fourMonthExpense.entries.map((entry) => Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        child: Text(
                            '4-Month Period: ${entry.key}, Expenses: ${entry.value.toStringAsFixed(2)}'))),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Expenses by Type')),
                    if (fourMonthExpenseByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No expenses by type'))
                    else
                      ...fourMonthExpenseByType.entries.map((entry) => Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('4-Month Period: ${entry.key}'),
                                ...entry.value.entries
                                    .map((typeEntry) => Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: Text(
                                              '${typeEntry.key}: ${typeEntry.value.toStringAsFixed(2)}'),
                                        )),
                              ],
                            ),
                          )),
                    SizedBox(height: 16),
                    BarChart(
                      data: fourMonthExpenseByType,
                      title: 'Four-Month Expenses Bar Chart',
                    ),
                    SizedBox(height: 16),
                    ...fourMonthRevenue.entries.map((entry) => Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        child: Text(
                            '4-Month Period: ${entry.key}, Revenue: ${entry.value.toStringAsFixed(2)}'))),
                    SizedBox(height: 8),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Revenue by Type')),
                    if (fourMonthRevenueByType.isEmpty)
                      Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                          child: Text('No revenue by type'))
                    else
                      ...fourMonthRevenueByType.entries.map((entry) => Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('4-Month Period: ${entry.key}'),
                                ...entry.value.entries
                                    .map((typeEntry) => Padding(
                                          padding: EdgeInsets.only(left: 16),
                                          child: Text(
                                              '${typeEntry.key}: ${typeEntry.value.toStringAsFixed(2)}'),
                                        )),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ][_selectedIndex],
    );
  }
}
