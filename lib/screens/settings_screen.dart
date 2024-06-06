import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();

    // Fetch category count from Firestore
    initUserInfo();
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
                      Padding(
                        padding: const EdgeInsets.only(left: 15, right: 15),
                        child: ElevatedButton(
                          onPressed: () {
                            FirebaseAuth.instance.signOut();
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
}
