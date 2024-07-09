import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = currencies.removeAt(oldIndex);
      currencies.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
                        height: 50,
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

  Widget _buildAllowanceInformation() {
    return ReorderableListView(
      scrollDirection: Axis.horizontal,
      onReorder: _onReorder,
      children: currencies.map((item) {
        return SizedBox(
          key: UniqueKey(),
          width: 50,
          child: Text(item)
        );
      }).toList(),
    );
  }
}
