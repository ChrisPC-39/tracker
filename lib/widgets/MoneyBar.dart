import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MoneyBar extends StatefulWidget {
  const MoneyBar({Key? key}) : super(key: key);

  @override
  State<MoneyBar> createState() => _MoneyBarState();
}

class _MoneyBarState extends State<MoneyBar> {
  double progress = 0;
  int monthlyAllowance = 0;
  int totalSpent = 0;
  String currency = "";
  List<dynamic> currencies = [];
  int currentCurrencyIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      monthlyAllowance = userDoc.get('monthly_allowance') as int;
      currencies = userDoc.get('currencies') as List<dynamic>;

      if (currencies.isNotEmpty) {
        currency = currencies.first;
      } else {
        currency = "";
      }
    });

    _calculateTotalSpent(currency);
  }

  int parseIntFromString(String str) {
    // Replace commas with dots to handle European-style decimals
    String normalizedStr = str.replaceAll(',', '.');

    // Use double.parse to handle potential decimal values
    double parsedValue = double.parse(normalizedStr);

    // Convert to integer (truncates any decimals)
    return parsedValue.toInt();
  }

  Future<void> _calculateTotalSpent(String currency) async {
    DateTime now = DateTime.now();
    int currentMonth = now.month;
    int currentYear = now.year;

    QuerySnapshot transactions = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('transactions')
        .where('timestamp',
            isGreaterThanOrEqualTo: DateTime(currentYear, currentMonth))
        .where('timestamp', isLessThan: DateTime(currentYear, currentMonth + 1))
        .where('currency', isEqualTo: currency)
        .get();

    int total = 0;
    for (QueryDocumentSnapshot doc in transactions.docs) {
      total += parseIntFromString(doc['total_price']);
    }

    setState(() {
      totalSpent = total;
      progress = totalSpent / monthlyAllowance;
      if (progress > 1.0) {
        progress = 1.0;
      } else if (progress < 0.0 || progress.isNaN) {
        progress = 0.0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(currencies.length, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: index == currentCurrencyIndex
                    ? totalSpent > monthlyAllowance
                        ? Colors.red[400]
                        : Colors.blue[400]
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(50),
              ),
            );
          }),
        ),
        SizedBox(
          height: 75,
          child: PageView.builder(
            itemCount: currencies.length,
            onPageChanged: (index) {
              setState(() {
                currency = currencies[index];
                currentCurrencyIndex = index;
                _calculateTotalSpent(currency);
              });
            },
            itemBuilder: (context, index) {
              String currentCurrency = currencies[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    currentCurrency.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 25,
                        width: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey[300],
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 200 * progress,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: totalSpent > monthlyAllowance
                                    ? Colors.red[400]
                                    : Colors.blue[400],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "${totalSpent.toStringAsFixed(0)} / ${monthlyAllowance.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
