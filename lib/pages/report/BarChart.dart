import 'package:flutter/material.dart';

class BarChart extends StatefulWidget {
  final Map<String, Map<String, double>> data; // Date -> Type -> Amount
  final String title; // e.g., "Daily Expenses", "Monthly Expenses"
  final double barWidth; // Maximum width for the bars

  const BarChart({
    super.key,
    required this.data,
    required this.title,
    this.barWidth = 300,
  });

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  late double maxAmount;
  late double totalSum; // Sum of all items
  String? _expandedBar;

  @override
  void initState() {
    super.initState();
    _calculateValues();
  }

  void _calculateValues() {
    maxAmount = 0;
    totalSum = 0;
    widget.data.forEach((date, types) {
      types.forEach((type, amount) {
        if (amount > maxAmount) maxAmount = amount;
        totalSum += amount; // Sum all amounts
      });
    });
    if (maxAmount == 0) maxAmount = 100; // Default max if no data
    if (totalSum == 0) totalSum = 1; // Avoid division by zero
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen width to constrain the bar width
    final double screenWidth = MediaQuery.of(context).size.width;
    final double adjustedBarWidth = widget.barWidth
        .clamp(0, screenWidth - 100); // Leave space for padding and text

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // Enable horizontal scrolling
      child: ConstrainedBox(
        constraints: BoxConstraints(
            minWidth: screenWidth), // Ensure at least screen width
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            if (widget.data.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('No data available'),
              )
            else
              ...widget.data.entries.map((entry) {
                String date = entry.key;
                Map<String, double> types = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        'Date: ${_formatDate(date)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...types.entries.map((typeEntry) => _bar(
                          date,
                          typeEntry.key,
                          typeEntry.value,
                          adjustedBarWidth, // Pass adjusted bar width
                        )),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _bar(
      String date, String typeName, double amount, double adjustedBarWidth) {
    double percentage =
        (amount / totalSum) * 100; // Percentage based on total sum
    String barKey = '$date-$typeName';
    bool isExpanded = _expandedBar == barKey;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Prevent row from taking full width
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedBar = isExpanded ? null : barKey;
              });
            },
            child: Container(
              width: isExpanded
                  ? adjustedBarWidth
                  : (adjustedBarWidth * (amount / maxAmount))
                      .clamp(0.0, adjustedBarWidth), // Clamp width
              height: 20,
              color: isExpanded
                  ? Colors.blueAccent.withOpacity(0.3)
                  : Colors.blueAccent,
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  typeName,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            // Use Flexible instead of Expanded to avoid forcing width
            child: Text(
              '${percentage.toStringAsFixed(1)}% (${amount.toStringAsFixed(2)})',
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateKey) {
    List<String> parts = dateKey.split('-');
    if (parts.length == 3) {
      // Daily: YYYY-MM-DD
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } else if (parts.length == 2 && parts[1].length <= 2) {
      // Monthly: YYYY-MM
      return '${parts[1]}/${parts[0]}';
    } else {
      // Four-month: YYYY-Q
      return 'Quarter ${parts[1]} ${parts[0]}';
    }
  }
}
