import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/screens/category_transaction_screen.dart';
import 'package:finance_tracker/screens/generative_transaction_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../widgets/AnimatedGradient.dart';
import '../widgets/ContrastCalculator.dart';
import '../widgets/DateFormatter.dart';
import '../widgets/GradientThemes.dart';
import '../widgets/MoneyBar.dart';
import 'transaction_screen.dart';

class FinScreen extends StatefulWidget {
  const FinScreen({Key? key}) : super(key: key);

  @override
  State<FinScreen> createState() => _FinScreenState();
}

class _FinScreenState extends State<FinScreen> {
  int _categoryCount = 0;
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
        final categories = snapshot.data()!['categories'] as List<dynamic>;
        setState(() {
          _categoryCount = categories.length;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
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
                  builder: (context) => GenerativeTransactionScreen(
                    parentScreen: const FinScreen(),
                    isCamera: false,
                    paymentTypes: paymentTypes,
                    currencies: currencies,
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
                  builder: (context) => GenerativeTransactionScreen(
                    parentScreen: const FinScreen(),
                    isCamera: true,
                    paymentTypes: paymentTypes,
                    currencies: currencies,
                  ),
                ),
              );
            },
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedGradient(gradientTheme: GradientTheme.finColors),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: false,
                snap: false,
                floating: false,
                expandedHeight: 150.0,
                elevation: 5,
                stretch: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    DateFormat.MMMM('en_US').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: const MoneyBar(),
                ),
              ),
              _categoryCount == 0
                  ? const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()))
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: _categoryCount,
                        (BuildContext context, int index) {
                          return categoryStream(index);
                        },
                      ),
                    ),
            ],
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
          final categories = userData['categories'] as List<dynamic>;
          final category = categories[index];
          currencies = userData['currencies'] as List<dynamic>;
          paymentTypes = userData['paymentTypes'] as List<dynamic>;

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
      child: SizedBox(
        height: 210,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: const Alignment(0, 25),
              child: Card(
                child: SizedBox(height: 200, child: _getTransactions(type)),
              ),
            ),
            Align(
              alignment: const Alignment(0, -1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {},
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(colorValue),
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
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
                          child: Icon(
                            IconData(codepoint, fontFamily: 'MaterialIcons'),
                            color: ContrastCalculator.getIconColor(
                              Color(colorValue),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(type)
                ],
              ),
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
          .limit(3)
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
                      parentScreen: const FinScreen(),
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
