import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/ParseUtils.dart';

class SettingsScreen extends StatefulWidget {
  final Widget parentScreen;

  const SettingsScreen({
    Key? key,
    required this.parentScreen,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoadingUsers = true;
  String email = "";
  List<dynamic> currencies = [];
  List<double> monthlyAllowance = [];
  String currency = "";

  @override
  void initState() {
    super.initState();

    // Fetch category count from Firestore
    initUserInfo();
    _loadAllowanceData();
  }

  Future<void> _loadAllowanceData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      for (int i = 0; i < userDoc['monthly_allowance'].length; i++) {
        monthlyAllowance.add(ParseUtils.parseDoubleFromString(
            userDoc['monthly_allowance'][i].toString()));
      }
      currencies = userDoc.get('currencies') as List<dynamic>;

      if (currencies.isNotEmpty) {
        currency = currencies.first;
      } else {
        currency = "";
      }
    });
  }

  Future<void> initUserInfo() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        setState(() {
          email = snapshot.data()!['email'] as String;
          currencies = snapshot.data()!['currencies'] as List<dynamic>;
        });
      }
    });

    setState(() {
      _isLoadingUsers = false;
    });
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = currencies.removeAt(oldIndex);
      currencies.insert(newIndex, item);
      final double allowanceItem = monthlyAllowance.removeAt(oldIndex);
      monthlyAllowance.insert(newIndex, allowanceItem);
    });

    // Update Firestore with the new order
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'currencies': currencies,
      'monthly_allowance': monthlyAllowance,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
              maxWidth: 600
          ),
          child: CustomScrollView(
            cacheExtent: 1000,
            slivers: [
              SliverAppBar(
                pinned: false,
                snap: false,
                floating: false,
                expandedHeight: 150.0,
                elevation: 5,
                leading: IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => widget.parentScreen),
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                flexibleSpace: const FlexibleSpaceBar(
                  title: Icon(
                    Icons.account_circle_rounded,
                    color: Colors.grey,
                    size: 45,
                  ),
                  centerTitle: true,
                ),
              ),
              _isLoadingUsers
                  ? const SliverToBoxAdapter(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _buildAccountInformation(),
                          SizedBox(
                            height: kIsWeb ? 100 : 75,
                            child: _buildAllowanceInformation(),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 15, right: 15),
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                setState(() {});
                              },
                              child: const Text("Sign out"),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountInformation() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          title: Text("Email:\n$email"),
        ),
      ),
    );
  }

  Widget proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return Material(
          elevation: 1,
          color: Colors.transparent,
          shadowColor: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
          child: child,
        );
      },
      child: child,
    );
  }

  Widget _buildAllowanceInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: ReorderableListView(
        proxyDecorator: proxyDecorator,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        onReorder: _onReorder,
        children: List.generate(
          currencies.length,
          (index) {
            return Card(
              key: ValueKey(currencies[index]),
              child: InkWell(
                onTap: () {
                  _showEditAllowanceDialog(index);
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencies[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${monthlyAllowance[index]}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showEditAllowanceDialog(int index) {
    TextEditingController currencyController = TextEditingController();
    TextEditingController allowanceController = TextEditingController();
    currencyController.text = currencies[index].toString();
    allowanceController.text = monthlyAllowance[index].toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Currency'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Edit currency name"),
              TextField(
                controller: currencyController,
                decoration: const InputDecoration(
                  hintText: 'Enter currency name',
                ),
              ),
              const SizedBox(height: 20),
              const Text("Edit monthly allowance"),
              TextField(
                controller: allowanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter allowance',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  monthlyAllowance.removeAt(index);
                  currencies.removeAt(index);
                });

                // Update Firestore with the removed entries
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({
                  'monthly_allowance':
                      monthlyAllowance.map((e) => e.toString()).toList(),
                  'currencies': currencies,
                });

                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  currencies[index] = currencyController.text;
                  monthlyAllowance[index] = double.parse(
                    allowanceController.text,
                  );
                });

                // Update Firestore with the new allowance
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .update({
                  'currencies': currencies,
                  'monthly_allowance': monthlyAllowance,
                });

                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
