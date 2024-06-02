import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/GeminiUtils.dart';

class GenerativeTransactionScreen extends StatefulWidget {
  final Widget parentScreen;
  final bool isCamera;
  final List<dynamic> currencies;
  final List<dynamic> paymentTypes;

  const GenerativeTransactionScreen({
    Key? key,
    required this.parentScreen,
    required this.isCamera,
    required this.currencies,
    required this.paymentTypes,
  }) : super(key: key);

  @override
  State<GenerativeTransactionScreen> createState() =>
      _GenerativeTransactionScreenState();
}

class _GenerativeTransactionScreenState
    extends State<GenerativeTransactionScreen> {
  PageController pageController = PageController();
  int currPage = 0;

  final ImagePicker picker = ImagePicker();
  bool _isGenerating = false;
  List<XFile?> files = [];
  List<int> erroneousFileIndices = [];

  Map<String, dynamic> jsonData = {};
  String store = "New transaction";
  String totalPrice = "";
  String currency = "";
  String payment = "";
  String category = "";
  List<dynamic> items = [];
  List<dynamic> pieces = [];
  List<dynamic> prices = [];

  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];

  @override
  void initState() {
    super.initState();

    currencies = widget.currencies;
    paymentTypes = widget.paymentTypes;

    if (widget.isCamera) {
      pickImageFromCamera();
    }
  }

  Future pickImageFromGallery() async {
    final List<XFile?> pickedImages = await picker.pickMultiImage();

    if (pickedImages.isEmpty) {
      return;
    }

    setState(() {
      files += pickedImages;
    });
  }

  Future pickImageFromCamera() async {
    final XFile? pickedImage = await ImagePicker.platform
        .getImageFromSource(source: ImageSource.camera);

    if (pickedImage == null) {
      return;
    }

    setState(() {
      files.add(pickedImage);
    });
  }

  Future<Map<String, dynamic>> sentPromptToAI(List<XFile?> files) async {
    List<String> categories = ["Groceries", "Transport", "Services", "Shopping", "Travel", "Restaurants", "Health", "Entertainment", "General"];
    List<String> paymentTypes = ["Card", "Cash", "None"];
    final GeminiUtils geminiUtils = GeminiUtils();
    final model = FirebaseVertexAI.instance.generativeModel(
      model: GeminiUtils.model,
      systemInstruction: Content.system(geminiUtils.getFinInstructions(categories, paymentTypes)),
    );

    print("FILES: ${files.length}");
    if (files.isNotEmpty) {
      final prompt = TextPart("What's in the picture?");
      List<DataPart> imageParts = [];
      for (int i = 0; i < files.length; i++) {
        Uint8List file = await files[i]!.readAsBytes();
        imageParts.add(DataPart('image/jpeg', file));
      }

      setState(() {
        _isGenerating = true;
      });

      final response = await model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);

      setState(() {
        _isGenerating = false;
      });

      try {
        Map<String, dynamic> jsonData = jsonDecode(response.text!);
        print(jsonData);
        return jsonData;
      } catch (e) {
        print('Error parsing JSON: $e');
      }

      return {'error': "empty"};
    }

    return {'error': "empty"};
  }

  Future<String> getImageToText(final imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(InputImage.fromFilePath(imagePath));
    String text = recognizedText.text.toString();
    return text;
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
      child: Scaffold(
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
            },
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: pageController,
                    children: [
                      _buildImagePage(),
                      _buildTransactionPage(),
                    ],
                  ),
                ),
                Visibility(
                  visible: currPage == 1,
                  child: Container(
                    color: Colors.lightGreen[400],
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => widget.parentScreen,
                                ),
                              );
                            },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              try {
                                CollectionReference transactions =
                                    FirebaseFirestore
                                        .instance
                                        .collection('users')
                                        .doc(FirebaseAuth
                                            .instance.currentUser!.uid)
                                        .collection('transactions');

                                await transactions.add({
                                  'store': store,
                                  'total_price': totalPrice,
                                  'currency': currency,
                                  'payment': payment,
                                  'category': category,
                                  'items': items,
                                  'pieces': pieces,
                                  'prices': prices,
                                  'timestamp': Timestamp.fromDate(
                                    DateTime.now(),
                                  ),
                                });

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => widget.parentScreen,
                                  ),
                                );
                              } catch (e) {
                                print("Error adding transaction: $e");
                              }
                            },
                            child: const Text("Save"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                  visible: currPage == 0,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => widget.parentScreen,
                              ),
                            );
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            if (files.isEmpty) {
                              return;
                            }

                            List<XFile?> filteredImages = [];
                            setState(() {
                              erroneousFileIndices = [];
                            });
                            for (int i = 0; i < files.length; i++) {
                              final text = await getImageToText(files[i]!.path);
                              if (text.isNotEmpty) {
                                filteredImages.add(files[i]);
                              } else {
                                erroneousFileIndices.add(i);
                              }
                            }
                            if (erroneousFileIndices.isNotEmpty) {
                              _showErrorsDialog(context);
                            }
                            if (filteredImages.isNotEmpty) {
                              jsonData = await sentPromptToAI(filteredImages);
                              pageController.nextPage(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeIn,
                              );
                              currPage += 1;
                              setState(() {});
                            }
                          },
                          child: files.isEmpty
                              ? const Text("Continue manually")
                              : const Text("Process images"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Visibility(
              visible: _isGenerating,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Processing... please wait",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionPage() {
    return Container(
      color: Colors.lightGreen[400],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          //! LIST VIEW
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: jsonData.isEmpty ? 0 : jsonData['items'].length,
              itemBuilder: (BuildContext context, int index) {
                // Access the extracted information
                store = jsonData['store'];
                items = jsonData['items'];
                category = jsonData['category'];
                // currency = jsonData['currency'];
                // payment = jsonData['payment'];
                pieces = jsonData['pieces'];
                prices = jsonData['prices'];
                totalPrice = jsonData['total_price'];
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
    );
  }

  Widget _buildItem(int index) {
    return ListTile(
      leading: SizedBox(
        width: 40,
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
        },
      ),
      trailing: SizedBox(
        width: 75,
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
          },
        ),
      ),
    );
  }

  Widget _buildCurrencyMenu() {
    return DropdownButton(
      value: currency.isEmpty ? currencies.first : currency,
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

  Widget _buildPaymentMenu() {
    return DropdownButton(
      value: payment.isEmpty ? paymentTypes.first : payment,
      alignment: Alignment.center,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
      ),
      onChanged: (value) {
        setState(() {
          payment = value.toString();
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

  Widget _buildImagePage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        shrinkWrap: true,
        itemCount: files.length + 2,
        itemBuilder: (context, index) {
          if (index == files.length) {
            return buildEmptyTile(
              Icons.camera_alt_outlined,
              pickImageFromCamera,
            );
          }
          if (index == files.length + 1) {
            return buildEmptyTile(
              Icons.add_photo_alternate_outlined,
              pickImageFromGallery,
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(files[index]!.path),
                  width: double.maxFinite,
                  height: double.maxFinite,
                  fit: BoxFit.fill,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  splashColor: Colors.black.withOpacity(0.25),
                  onTap: () {
                    _showOptionsDialog(context, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget buildEmptyTile(IconData iconData, Function() onPressed) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.grey[300],
          ),
        ),
        Center(
          child: Icon(
            iconData,
            size: 40,
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            splashColor: Colors.black.withOpacity(0.25),
            onTap: () => onPressed(),
          ),
        ),
      ],
    );
  }

  Future<void> _showErrorsDialog(BuildContext context) async {
    String indicesString = erroneousFileIndices.join(', ');

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "No text has been detected in the following files: $indicesString",
                ),
                const Text("\nDo you want to delete them automatically?"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                for (int i = 0; i < erroneousFileIndices.length; i++) {
                  files.removeAt(erroneousFileIndices[i]);
                }
                setState(() {});
                Navigator.of(context).pop();
              },
              child: const Text("Delete and continue"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOptionsDialog(BuildContext context, int index) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    files.removeAt(index);
                  });
                  Navigator.of(context).pop();
                },
                child: const Text("Delete"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
