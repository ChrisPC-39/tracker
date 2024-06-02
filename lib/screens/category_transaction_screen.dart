import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/DateFormatter.dart';
import 'transaction_screen.dart';

class CategoryTransactionScreen extends StatefulWidget {
  final String type;
  final Widget parentScreen;

  const CategoryTransactionScreen({
    Key? key,
    required this.parentScreen,
    required this.type,
  }) : super(key: key);

  @override
  State<CategoryTransactionScreen> createState() =>
      _CategoryTransactionScreenState();
}

class _CategoryTransactionScreenState extends State<CategoryTransactionScreen> {
  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.parentScreen),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.lightGreen[400],
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => widget.parentScreen),
              );
            },
            icon: const Icon(Icons.arrow_back),
          ),
          title: Text(widget.type),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Center(child: Text('Error: ${userSnapshot.error}'));
            }

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            currencies = userData['currencies'] as List<dynamic>;
            paymentTypes = userData['paymentTypes'] as List<dynamic>;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser!.uid)
                  .collection('transactions')
                  .where('category', isEqualTo: widget.type)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Handle empty collection
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions found'));
                }

                return ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    final String store = doc['store'];
                    final String totalPrice = doc['total_price'];
                    final String currency = doc['currency'];
                    final Timestamp timestamp = doc['timestamp'];

                    return InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionScreen(
                              doc: doc,
                              currencies: currencies,
                              paymentTypes: paymentTypes,
                              parentScreen: CategoryTransactionScreen(
                                parentScreen: widget.parentScreen,
                                type: widget.type,
                              ),
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        title: Text(store),
                        subtitle:
                            Text(DateFormatter.formatTimestamp(timestamp)),
                        trailing: Text(
                          "-$totalPrice $currency",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
