import 'package:aifinance/database/models.dart';

// asset liability expenses revenue

List<ItemType> defaultTypes = [
  // expenses
  ItemType(type: 'Food', source: "Expense"),
  ItemType(type: 'Clothes', source: "Expense"),
  ItemType(type: 'House Maintenance', source: "Expense"),
  ItemType(type: 'Transport', source: "Expense"),
  ItemType(type: 'Health', source: "Expense"),
  ItemType(type: 'Entertainment', source: "Expense"),
  ItemType(type: 'Education', source: "Expense"),
  ItemType(type: 'Gifts', source: "Expense"),
  ItemType(type: 'Charity', source: "Expense"),
  ItemType(type: 'Travel', source: "Expense"),
  ItemType(type: 'Insurance', source: "Expense"),
  ItemType(type: 'Productivity', source: "Expense"),
  // revenue
  ItemType(type: 'Work', source: "Revenue"),
  ItemType(type: 'Investment', source: "Revenue"),
];

// assets
// ItemType(type: 'Bank Account', source: "Asset"),
// ItemType(type: 'Cash', source: "Asset"),
// // liabilities
// ItemType(type: 'Bank Loan', source: "Liability"),
// ItemType(type: 'Debt', source: "Liability"),

List<List<ItemCategory>> defaultCategories = [
  // Expense categories
  // food
  [
    ItemCategory(category: 'Breakfast'),
    ItemCategory(category: 'Lunch'),
    ItemCategory(category: 'Dinner'),
    ItemCategory(category: 'Snacks'),
  ],
  // clothings
  [
    ItemCategory(category: 'Shirts'),
    ItemCategory(category: 'Pants'),
  ],
  // house
  [
    ItemCategory(category: 'Repairs'), // House Maintenance
    ItemCategory(category: 'Cleaning'),
  ],
  // transport
  [
    ItemCategory(category: 'Bus'), // Transport
    ItemCategory(category: 'Taxi'),
    ItemCategory(category: 'Metro'),
  ],
  // health
  [
    ItemCategory(category: 'Doctor'),
    ItemCategory(category: 'Medications'),
  ],
  // entertainment
  [
    ItemCategory(category: 'Movies'),
    ItemCategory(category: 'Concerts'),
  ],
  // education
  [
    ItemCategory(category: 'Tuition'),
    ItemCategory(category: 'Books'),
  ],
  // gifts
  [
    ItemCategory(category: 'Birthday'),
    ItemCategory(category: 'Holidays'),
  ],
  // charity
  [
    ItemCategory(category: 'Charitable Donations'),
  ],
  // travel
  [
    ItemCategory(category: 'Flights'),
    ItemCategory(category: 'Amusement'),
    ItemCategory(category: 'Meals'),
    ItemCategory(category: 'Accommodation'),
    ItemCategory(category: 'Insurance'),
  ],
  // insurance
  [
    ItemCategory(category: 'Health Insurance'),
    ItemCategory(category: 'Auto Insurance'),
  ],
  // productivity
  [
    ItemCategory(category: 'Tools'),
  ],

  // Revenue
  // work
  [
    ItemCategory(category: 'Salary'),
    ItemCategory(category: 'Bonus'),
  ],

  // invesement
  [
    ItemCategory(category: 'Dividend'),
  ],

  // // Assets
  // // savings
  // [
  //   ItemCategory(category: 'Cash'),
  //   ItemCategory(category: 'Bank'),
  //   ItemCategory(category: 'Credit Card'),
  // ],
  // // investment
  // [
  //   ItemCategory(category: 'Stocks'),
  //   ItemCategory(category: 'Crypto'),
  //   ItemCategory(category: 'Real Estate'),
  //   ItemCategory(category: 'Commodities'),
  // ],
  // // liabilities
  // // bank loan
  // [
  //   ItemCategory(category: 'Loan Interest'),
  // ],
  // // debt
  // [
  //   ItemCategory(category: 'Debt Interest'),
  // ],
];

List<Capital> defaultCapital = [
  Capital(
    amount: 0,
    type: 'Cash',
    fav: false,
    source: 'Asset',
    currency: "USD",
  ),
  Capital(
    amount: 0,
    type: 'Bank Account',
    fav: false,
    source: 'Asset',
    currency: "USD",
  ),
  Capital(
    amount: 0,
    type: 'PayPal',
    fav: false,
    source: 'Asset',
    currency: "USD",
  ),
  Capital(
    amount: 0,
    type: 'Credit Card',
    fav: false,
    source: 'Liability',
    currency: "USD",
  ),
];
