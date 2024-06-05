import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/ParseUtils.dart';

class MoneyBar extends StatefulWidget {
  const MoneyBar({Key? key}) : super(key: key);

  @override
  State<MoneyBar> createState() => _MoneyBarState();
}

class _MoneyBarState extends State<MoneyBar> {
  double progress = 0;
  double monthlyAllowance = 0;
  double totalSpent = 0;
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
      monthlyAllowance = ParseUtils.parseDoubleFromString(
          userDoc['monthly_allowance'].toString());
      currencies = userDoc.get('currencies') as List<dynamic>;

      if (currencies.isNotEmpty) {
        currency = currencies.first;
      } else {
        currency = "";
      }
    });
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

    double total = 0;
    for (QueryDocumentSnapshot doc in transactions.docs) {
      total += ParseUtils.parseDoubleFromString(doc['total_price']);
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
    return SizedBox(
      height: 75,
      child: Column(
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
                          : Colors.purple[400]
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(50),
                ),
              );
            }),
          ),
          SizedBox(
            height: 75,
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: currencies.length,
              onPageChanged: (newPageIndex) {
                setState(() {
                  currency = currencies[newPageIndex];
                  currentCurrencyIndex = newPageIndex;
                });
              },
              itemBuilder: (context, index) {
                return _buildCurrency(index);
              },
            ),
          ),
        ],
      ),
      // child: RotatedBox(
      //   quarterTurns: -1,
      //   child: ListWheelScrollView(
      //     itemExtent: 250,
      //     onSelectedItemChanged: (newIndex) {
      //       currency = currencies[newIndex];
      //       setState(() {});
      //     },
      //     children: List.generate(
      //         currencies.length, (index) => _buildCurrency(index)),
      //   ),
      // ),
    );
  }

  Widget _buildCurrency(int index) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('transactions')
            .where('timestamp',
                isGreaterThanOrEqualTo:
                    DateTime(DateTime.now().year, DateTime.now().month))
            .where('timestamp',
                isLessThan:
                    DateTime(DateTime.now().year, DateTime.now().month + 1))
            .where('currency', isEqualTo: currency)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          double total = 0;
          for (QueryDocumentSnapshot doc in snapshot.data!.docs) {
            total +=
                ParseUtils.parseDoubleFromString(doc['total_price'].toString());
          }

          totalSpent = total;
          progress = totalSpent / monthlyAllowance;
          if (progress > 1.0) {
            progress = 1.0;
          } else if (progress < 0.0 || progress.isNaN) {
            progress = 0.0;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currencies[index].toUpperCase(),
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
                      color: Colors.grey[200],
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: totalSpent > monthlyAllowance
                              ? Colors.red[300]
                              : Colors.purple[300],
                        ),
                        duration: const Duration(milliseconds: 300),
                        width:
                            currency == currencies[index] ? 200 * progress : 0,
                        child: Container(),
                      ),
                    ),
                  ),
                  Text(
                    "${currency == currencies[index] ? totalSpent.toStringAsFixed(2) : 0.0} / ${monthlyAllowance.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        });
  }
}
