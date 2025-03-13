import 'package:cloud_firestore/cloud_firestore.dart';

// sources: assets, liability, expenses, revenue
class Item {
  String? id;
  final String? currency;
  final double? amount;
  final String? typeID;
  final String? source;
  final DateTime? time;
  final String? categoryID;
  final String? paymentID; // e.g. cash, bank, credit card...
  Item({
    this.id,
    this.currency,
    this.amount,
    this.typeID,
    this.source,
    this.time,
    this.categoryID,
    this.paymentID,
  });

  factory Item.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Item(
      id: snapshot.id,
      currency: data?['currency'],
      amount: data?['amount'],
      typeID: data?['typeID'],
      source: data?['source'],
      time: data?['time'] != null
          ? (data?['time'] is Timestamp
              ? (data?['time'] as Timestamp).toDate()
              : data?['time'] is String
                  ? DateTime.parse(data?['time'] as String)
                  : null)
          : null,
      categoryID: data?['categoryID'],
      paymentID: data?['paymentID'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (currency != null) "currency": currency,
      if (amount != null) "amount": amount,
      if (typeID != null) "typeID": typeID,
      if (source != null) "source": source,
      if (time != null) "time": time,
      if (categoryID != null) "categoryID": categoryID,
      if (paymentID != null) "paymentID": paymentID,
    };
  }
}

class ItemType {
  String? id;
  final String? type;
  final String? source;

  ItemType({
    this.id,
    this.type,
    this.source,
  });

  factory ItemType.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();

    return ItemType(
      id: snapshot.id,
      type: data?['type'],
      source: data?['source'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (type != null) "type": type,
      if (source != null) "source": source,
    };
  }
}

class ItemCategory {
  String? id;
  String? category;
  final bool fav;

  ItemCategory({
    this.id,
    this.category,
    this.fav = false,
  });

  factory ItemCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return ItemCategory(
      id: snapshot.id,
      category: data?['category'],
      fav: data?['fav'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (category != null) "category": category,
      "fav": fav,
    };
  }
}

class Capital {
  // assets, liabilities
  String? id; // paymentID for Items
  double? amount;
  String? type;
  String? source;
  String? currency;
  bool fav;

  Capital({
    this.id,
    this.amount,
    this.type,
    this.source,
    this.currency,
    this.fav = false,
  });

  factory Capital.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return Capital(
      id: snapshot.id,
      amount: data?['amount'],
      type: data?['type'],
      source: data?['source'],
      currency: data?['currency'],
      fav: data?['fav'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (amount != null) "amount": amount,
      if (type != null) "type": type,
      if (source != null) "source": source,
      if (currency != null) "currency": currency,
      "fav": fav,
    };
  }
}

class UserCurrency {
  String currency;
  UserCurrency({
    required this.currency,
  });

  factory UserCurrency.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return UserCurrency(
      currency: data?['currency'],
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      "currency": currency,
    };
  }
}

class ExchangePair {
  String? id;
  String currency1;
  String currency2;
  ExchangePair({
    this.id,
    required this.currency1,
    required this.currency2,
  });

  factory ExchangePair.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return ExchangePair(
      id: snapshot.id,
      currency1: data?['cur1'],
      currency2: data?['cur2'],
    );
  }
  Map<String, dynamic> toFirestore() {
    return {
      "currency1": currency1,
      "currency2": currency2,
    };
  }
}
