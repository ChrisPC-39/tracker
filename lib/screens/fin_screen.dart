import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/ContrastCalculator.dart';
import '../widgets/DateFormatter.dart';
import '../widgets/MoneyBar.dart';
import 'category_transaction_screen.dart';
import 'new_transaction_screen.dart';
import 'transaction_screen.dart';

class FinScreen extends StatefulWidget {
  const FinScreen({Key? key}) : super(key: key);

  @override
  State<FinScreen> createState() => _FinScreenState();
}

class _FinScreenState extends State<FinScreen> {
  List<dynamic> categories = [];
  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];

  @override
  void initState() {
    super.initState();

    // Fetch category count from Firestore
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        final category = snapshot.data()!['categories'] as List<dynamic>;
        setState(() {
          categories = category;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "normalButton",
            mini: true,
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewTransactionScreen(
                    parentScreen: FinScreen(),
                    isCamera: false,
                    parentJson: {},
                  ),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "cameraButton",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewTransactionScreen(
                    parentScreen: FinScreen(),
                    isCamera: true,
                    parentJson: {},
                  ),
                ),
              );
            },
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: CustomScrollView(
        cacheExtent: 1000,
        slivers: [
          SliverAppBar(
            pinned: false,
            snap: false,
            floating: false,
            expandedHeight: 150.0,
            elevation: 5,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                DateFormat.MMMM('en_US').format(DateTime.now()),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: const MoneyBar(),
            ),
          ),
          categories.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: categories.length + 1,
                    (BuildContext context, int index) {
                      if (index == categories.length) {
                        return Container(height: 150);
                      }
                      return categoryStream(index);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget categoryStream(int index) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          categories = userData['categories'] as List<dynamic>;
          currencies = userData['currencies'] as List<dynamic>;
          paymentTypes = userData['paymentTypes'] as List<dynamic>;

          final category = categories[index];
          final int codepoint = category['codepoint'];
          final int colorValue = category['colorValue'];
          final String type = category['type'];

          return categoryCard(
            type: type,
            colorValue: colorValue,
            codepoint: codepoint,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget categoryCard({
    required int codepoint,
    required int colorValue,
    required String type,
  }) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryTransactionScreen(
                        parentScreen: const FinScreen(),
                        type: type,
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconData(codepoint, fontFamily: 'MaterialIcons'),
                      color: ContrastCalculator.getIconColor(
                        Color(colorValue),
                      ),
                    ),
                  ),
                  title: Text(type),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: _getTransactions(type),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTransactions(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('transactions')
          .where('category', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .limit(2)
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
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            final String store = doc['store'];
            final String totalPrice = doc['total_price'].toStringAsFixed(2);
            final String currency = doc['currency'];
            final Timestamp timestamp = doc['timestamp'];

            Map<String, dynamic> jsonData = {
              "items": doc['items'],
              "pieces": doc['pieces'],
              "prices": doc['prices'],
              "store": doc['store'],
              "total_price": doc['total_price'],
              "currency": doc['currency'],
              "payment": doc['payment'],
              "category": doc['category'],
              'timestamp': doc['timestamp']
            };


            return InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewTransactionScreen(
                      parentScreen: const FinScreen(),
                      parentJson: jsonData,
                    ),
                  ),
                );
              },
              child: ListTile(
                title: Text(store),
                subtitle: Text(DateFormatter.formatTimestamp(timestamp)),
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
  }
}
