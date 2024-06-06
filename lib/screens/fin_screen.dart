import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/ColorUtils.dart';
import '../utils/DateFormatter.dart';
import '../widgets/MoneyBar.dart';
import '../widgets/OptionsDialog.dart';
import 'category_transaction_screen.dart';
import 'transaction_screen.dart';

class FinScreen extends StatefulWidget {
  const FinScreen({Key? key}) : super(key: key);

  @override
  State<FinScreen> createState() => _FinScreenState();
}

class _FinScreenState extends State<FinScreen> {
  bool _isLoadingCategories = true;
  List<dynamic> categories = [];
  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];

  @override
  void initState() {
    super.initState();

    // Fetch category count from Firestore
    initCategories();
  }

  Future<void> initCategories() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        final category = snapshot.data()!['categories'] as List<dynamic>;
        setState(() {
          categories = category;
          _isLoadingCategories = false;
        });
      }
    });

    setState(() {
      _isLoadingCategories = false;
    });
  }

  Future<void> updateCategoryName(
      Map<String, dynamic> userData,
      int index,
      DocumentReference ref,
      String newVal,
      int colorVal,
      int codePoint,
      ) async {
    final itemCategories = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('transactions')
        .where('category', isEqualTo: userData['categories'][index]['type'])
        .get();

    for (var transaction in itemCategories.docs) {
      transaction.reference.update({'category': newVal});
    }

    userData['categories'][index]['type'] = newVal;
    userData['categories'][index]['colorValue'] = colorVal;
    userData['categories'][index]['codepoint'] = codePoint;
    ref.update({'categories': userData['categories']});
  }

  Future<void> removeCategory(
      Map<String, dynamic> userData,
      int index,
      DocumentReference ref,
      ) async {
    final itemCategories = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('transactions')
        .where('category', isEqualTo: userData['categories'][index]['type'])
        .get();

    for (var transaction in itemCategories.docs) {
      transaction.reference.update({'category': ''});
    }

    userData['categories'].removeAt(index);
    ref.update({'categories': userData['categories']});
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
                  builder: (context) => const TransactionScreen(
                    parentScreen: FinScreen(),
                    isCamera: false,
                    parentJson: {},
                    parentCategory: "",
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
                  builder: (context) => const TransactionScreen(
                    parentScreen: FinScreen(),
                    isCamera: true,
                    parentJson: {},
                    parentCategory: "",
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
          _isLoadingCategories
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        _buildEmptyCategory(),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: categories.length + 2,
                    (BuildContext context, int index) {
                      if (index == categories.length) {
                        return _buildEmptyCategory();
                      }
                      if (index == categories.length + 1) {
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

  Widget _buildEmptyCategory() {
    const String categoryTitle = "New category";
    final int codepoint = Icons.add.codePoint;
    final int colorValue = Colors.grey.value;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final user = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .get();

                Map<String, dynamic> newCategory = {
                  'type': categoryTitle,
                  'codepoint': codepoint,
                  'colorValue': colorValue,
                };

                await user.reference.update({
                  'categories': FieldValue.arrayUnion([newCategory])
                });

                initCategories();
                setState(() {});
              },
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconData(codepoint, fontFamily: 'MaterialIcons'),
                    color: ColorUtils.getIconColor(
                      Color(colorValue),
                    ),
                  ),
                ),
                title: const Text(categoryTitle),
              ),
            ),
          ),
        ),
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
            snapshot: snapshot,
            index: index,
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
    required int index,
    required AsyncSnapshot<DocumentSnapshot<Object?>> snapshot,
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
                borderRadius: BorderRadius.circular(10),
                onLongPress: () {
                  showDeleteDialog(
                    actionText: "Delete",
                    context: context,
                    titleText: "Delete category",
                    onPressed: () async {
                      Map<String, dynamic> userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final DocumentReference ref = snapshot.data!.reference;
                      await removeCategory(
                        userData,
                        index,
                        ref,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FinScreen(),
                        ),
                      );
                    },
                  );
                },
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryTransactionScreen(
                        parentScreen: const FinScreen(),
                        type: type,
                        codePoint: codepoint,
                        colorValue: colorValue,
                        callBack: (newVal, colorValue, codepoint) {
                          Map<String, dynamic> userData =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final DocumentReference ref =
                              snapshot.data!.reference;
                          updateCategoryName(
                            userData,
                            index,
                            ref,
                            newVal,
                            colorValue,
                            codepoint,
                          );
                        },
                      ),
                    ),
                  );
                },
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      IconData(codepoint, fontFamily: 'MaterialIcons'),
                      color: ColorUtils.getIconColor(
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
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionScreen(
                      parentScreen: const FinScreen(),
                      parentJson: jsonData,
                      parentCategory: jsonData['category'],
                    ),
                  ),
                );
              },
              onLongPress: () {
                showDeleteDialog(
                  titleText: "Delete transaction",
                  context: context,
                  actionText: "Delete",
                  onPressed: () {
                    doc.reference.delete();
                    Navigator.of(context).pop();
                  },
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
