import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_iconpicker/flutter_iconpicker.dart';

import '../utils/ColorUtils.dart';
import '../utils/DateFormatter.dart';
import '../widgets/MyTextfield.dart';
import '../widgets/OptionsDialog.dart';
import 'new_transaction_screen.dart';

class CategoryTransactionScreen extends StatefulWidget {
  final String type;
  final int codePoint;
  final int colorValue;
  final Widget parentScreen;
  final Function(String, int, int) callBack;

  const CategoryTransactionScreen({
    Key? key,
    required this.parentScreen,
    required this.type,
    required this.callBack,
    required this.codePoint,
    required this.colorValue,
  }) : super(key: key);

  @override
  State<CategoryTransactionScreen> createState() =>
      _CategoryTransactionScreenState();
}

class _CategoryTransactionScreenState extends State<CategoryTransactionScreen> {
  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];
  String categoryName = "";
  int codepoint = 0;
  int colorValue = 0;
  Color pickerColor = Colors.blue;
  IconData? _icon;

  @override
  void initState() {
    super.initState();

    categoryName = widget.type;
    codepoint = widget.codePoint;
    colorValue = widget.colorValue;
    pickerColor = Color(widget.colorValue);
    _icon = IconData(codepoint, fontFamily: 'MaterialIcons');
  }

  void changeColor(Color color) {
    pickerColor = color;
  }

  void _showColorAndIconPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) {
            return AlertDialog(
              title: const Text('Choose Color'),
              content: SingleChildScrollView(
                child: MaterialPicker(
                  pickerColor: pickerColor,
                  onColorChanged: changeColor,
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        _pickIcon(setState);
                      },
                      icon: Icon(_icon),
                    ),
                    const Spacer(flex: 1),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                    TextButton(
                      child: const Text("Done"),
                      onPressed: () {
                        colorValue = pickerColor.value;
                        if (_icon != null) {
                          codepoint = _icon!.codePoint;
                        }
                        setState(() {});
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickIcon(void Function(void Function()) setState) async {
    IconData? icon = await showIconPicker(
      context,
      iconPackModes: [IconPack.material, IconPack.outlinedMaterial],
    );
    if (icon != null) {
      setState(() {
        _icon = icon;
      });
    }
  }

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
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: AppBar(
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
            title: MyTextField(
              text: categoryName,
              fontSize: 20,
              textInputType: TextInputType.text,
              hintText: 'Category',
              onSubmitted: (newVal) {
                categoryName = newVal;
              },
              onChanged: (newVal) {
                categoryName = newVal;
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(colorValue),
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _showColorAndIconPicker();
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(90),
                      child: Icon(
                        IconData(codepoint, fontFamily: 'MaterialIcons'),
                        color: ColorUtils.getIconColor(
                          Color(colorValue),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Visibility(
            visible: codepoint != widget.codePoint ||
                colorValue != widget.colorValue ||
                categoryName != widget.type,
            child: FloatingActionButton(
              onPressed: () {
                widget.callBack(categoryName, colorValue, codepoint);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => widget.parentScreen),
                );
              },
              child: const Icon(Icons.save_outlined),
            ),
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

              final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;
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
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewTransactionScreen(
                                  parentScreen: CategoryTransactionScreen(
                                    parentScreen: widget.parentScreen,
                                    type: widget.type,
                                    callBack: widget.callBack,
                                    colorValue: colorValue,
                                    codePoint: codepoint,
                                  ),
                                  parentJson: const {},
                                  parentCategory: widget.type,
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            title: Text(
                              "Create new",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            leading: Icon(Icons.add, color: Colors.grey[700]),
                          ),
                        ),
                        const Align(
                            alignment: Alignment.center,
                            child: Text('No transactions found')),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length + 1,
                    itemBuilder: (context, index) {
                      if (index == snapshot.data!.docs.length) {
                        return InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NewTransactionScreen(
                                  parentScreen: CategoryTransactionScreen(
                                    parentScreen: widget.parentScreen,
                                    type: widget.type,
                                    callBack: widget.callBack,
                                    colorValue: colorValue,
                                    codePoint: codepoint,
                                  ),
                                  parentJson: const {},
                                  parentCategory: widget.type,
                                ),
                              ),
                            );
                          },
                          child: ListTile(
                            title: Text(
                              "Create new",
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            leading: Icon(Icons.add, color: Colors.grey[700]),
                          ),
                        );
                      }

                      var doc = snapshot.data!.docs[index];
                      final String store = doc['store'];
                      final String totalPrice =
                          doc['total_price'].toStringAsFixed(2);
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
                                parentScreen: CategoryTransactionScreen(
                                  parentScreen: widget.parentScreen,
                                  type: widget.type,
                                  callBack: widget.callBack,
                                  colorValue: colorValue,
                                  codePoint: codepoint,
                                ),
                                parentJson: jsonData,
                                parentCategory: jsonData['category'],
                              ),
                            ),
                          );
                        },
                        onLongPress: () async {
                          final DocumentReference? transactionRef =
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser!.uid)
                                  .collection('transactions')
                                  .where('timestamp',
                                      isEqualTo: jsonData['timestamp'])
                                  .get()
                                  .then((snapshot) {
                            if (snapshot.docs.isNotEmpty) {
                              return snapshot.docs.first.reference;
                            } else {
                              return null;
                            }
                          });
                          showDeleteDialog(
                            titleText: "Delete image",
                            context: context,
                            actionText: "Delete",
                            onPressed: () {
                              transactionRef!.delete();
                              Navigator.of(context).pop();
                            },
                          );
                        },
                        child: ListTile(
                          title: Text(store),
                          subtitle:
                              Text(DateFormatter.formatTimestamp(timestamp)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "-$totalPrice $currency",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
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
      ),
    );
  }
}
