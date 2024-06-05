import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  final QueryDocumentSnapshot<Object?> doc;
  final List<dynamic> currencies;
  final List<dynamic> paymentTypes;
  final Widget parentScreen;

  const TransactionScreen({
    Key? key,
    required this.doc,
    required this.currencies,
    required this.parentScreen,
    required this.paymentTypes,
  }) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  Timestamp timestamp = Timestamp.fromMillisecondsSinceEpoch(0);
  String store = "";
  String totalPrice = "";
  String currency = "";
  String payment = "";
  List<dynamic> items = [];
  List<dynamic> pieces = [];
  List<dynamic> prices = [];
  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];

  @override
  void initState() {
    super.initState();

    store = widget.doc['store'];
    totalPrice = widget.doc['total_price'];
    currency = widget.doc['currency'];
    timestamp = widget.doc['timestamp'];
    items = widget.doc['items'];
    pieces = widget.doc['pieces'];
    prices = widget.doc['prices'];
    payment = widget.doc['payment'];
    currencies = widget.currencies;
    paymentTypes = widget.paymentTypes;
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
            title: TextField(
              controller: TextEditingController(text: store),
              keyboardType: TextInputType.text,
              textAlign: TextAlign.start,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8),
              ),
              style: const TextStyle(
                fontSize: 24,
              ),
              onSubmitted: (newVal) {
                setState(() {
                  store = newVal;
                });
                widget.doc.reference.update({'store': newVal});
              },
            ),
          ),
          body: Column(
            children: [
              //! LIST VIEW
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildItem(index);
                  },
                ),
              ),
              //! TOTAL
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(flex: 1),
                    SizedBox(
                      width: 80, // Adjust the width as needed
                      child: TextField(
                        controller: TextEditingController(text: totalPrice),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        style: const TextStyle(
                          fontSize: 22,
                        ),
                        onSubmitted: (newVal) {
                          setState(() {
                            totalPrice = newVal;
                          });
                          widget.doc.reference.update({'total_price': newVal});
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildCurrencyMenu(),
                  ],
                ),
              ),
              //! PAYMENT TYPE
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Paid with",
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(flex: 1),
                    const SizedBox(width: 10),
                    _buildPaymentMenu(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        child: TextField(
          controller: TextEditingController(text: pieces[index]),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.start,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          style: const TextStyle(
            fontSize: 20,
          ),
          onSubmitted: (newVal) {
            if (!newVal.contains("x")) {
              newVal += "x";
            }

            setState(() {
              pieces[index] = newVal;
            });
            widget.doc.reference.update({'pieces': pieces});
          },
        ),
      ),
      title: TextField(
        controller: TextEditingController(text: items[index]),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.start,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
        style: const TextStyle(
          fontSize: 20,
        ),
        onSubmitted: (newVal) {
          setState(() {
            items[index] = newVal;
          });
          widget.doc.reference.update({'items': items});
        },
      ),
      trailing: SizedBox(
        width: 50,
        child: TextField(
          controller: TextEditingController(text: prices[index]),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.start,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8),
          ),
          style: const TextStyle(
            fontSize: 20,
          ),
          onSubmitted: (newVal) {
            setState(() {
              prices[index] = newVal;
            });
            widget.doc.reference.update({'prices': prices});
          },
        ),
      ),
    );
  }

  Widget _buildPaymentMenu() {
    return DropdownButton(
      value: payment,
      alignment: Alignment.center,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
      ),
      onChanged: (value) {
        setState(() {
          payment = value.toString();
          widget.doc.reference.update({'payment': payment});
        });
      },
      items: [
        for (String payment in paymentTypes)
          DropdownMenuItem<String>(
            value: payment,
            child: Text(payment),
          )
      ],
    );
  }

  Widget _buildCurrencyMenu() {
    return DropdownButton(
      value: currency,
      alignment: Alignment.center,
      style: const TextStyle(
        fontSize: 22,
        color: Colors.black,
      ),
      onChanged: (value) {
        if (value == 'Add New Currency') {
          _showNewCurrencyDialog();
        } else {
          setState(() {
            currency = value.toString();
            widget.doc.reference.update({'currency': currency});
          });
        }
      },
      items: [
        for (String currency in currencies)
          DropdownMenuItem<String>(
            value: currency,
            child: Text(currency),
          ),
        const DropdownMenuItem<String>(
          value: 'Add New Currency',
          child: Text('+ New'),
        ),
      ],
    );
  }

  Future<void> _showNewCurrencyDialog() async {
    String? newCurrency;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Currency'),
          content: TextField(
            onChanged: (value) {
              newCurrency = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter new currency',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (newCurrency != null && newCurrency!.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({
                    'currencies': FieldValue.arrayUnion([newCurrency])
                  }).then((value) {
                    setState(() {
                      currencies.add(newCurrency!);
                    });
                    Navigator.pop(context);
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
