// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/GeminiUtils.dart';
import '../utils/ParseUtils.dart';
import '../widgets/MyTextfield.dart';
import '../widgets/OptionsDialog.dart';

class TransactionScreen extends StatefulWidget {
  final Widget parentScreen;
  final String parentCategory;
  final Map<String, dynamic> parentJson;
  final bool isCamera;

  const TransactionScreen({
    Key? key,
    required this.parentScreen,
    this.isCamera = false,
    required this.parentJson,
    required this.parentCategory,
  }) : super(key: key);

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  bool _isLoading = false;
  bool _hasChangedAmountOrPrice = false;
  PageController pageController = PageController();

  final ImagePicker picker = ImagePicker();
  bool _isGenerating = false;
  List<XFile?> files = [];
  List<int> erroneousFileIndices = [];

  Map<String, dynamic> jsonData = {
    "items": [],
    "pieces": [],
    "prices": [],
    "store": "Transaction",
    "total_price": 0.0,
    "currency": "",
    "payment": "card",
    "category": "",
  };

  List<dynamic> categories = [];
  List<dynamic> currencies = [];
  List<dynamic> paymentTypes = [];

  @override
  void initState() {
    super.initState();

    _loadUserData();
    if (widget.parentJson.isNotEmpty) {
      jsonData = widget.parentJson;
    } else {
      jsonData['category'] = widget.parentCategory;
    }
    if (widget.isCamera) {
      pickImageFromCamera();
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    setState(() {
      categories = userDoc.get('categories') as List<dynamic>;
      currencies = userDoc['currencies'] as List<dynamic>;
      paymentTypes = userDoc['paymentTypes'] as List<dynamic>;
      jsonData['currency'] = currencies.isEmpty ? "" : currencies.first;
      _isLoading = false;
    });
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

    if (widget.isCamera) {
      _buildModal(context);
    }
  }

  Future<Map<String, dynamic>> sendPromptToAI(String prompt) async {
    final model = FirebaseVertexAI.instance.generativeModel(
      model: GeminiUtils.model,
      systemInstruction: Content.system(GeminiUtils.getFinInstructions(
        ParseUtils.getCategoriesAsStringList(categories),
        ParseUtils.getDynamicListAsStringList(currencies),
      )),
    );

    if (prompt.isNotEmpty) {
      setState(() {
        _isGenerating = true;
      });

      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _isGenerating = false;
        // _hasChangedAmountOrPrice = true;
      });

      return GeminiUtils().validateOutput(response.text!);
    }

    return {};
  }

  Future<Map<String, dynamic>> sendFilesToAI(List<XFile?> files) async {
    final model = FirebaseVertexAI.instance.generativeModel(
      model: GeminiUtils.model,
      systemInstruction: Content.system(GeminiUtils.getFinInstructions(
        ParseUtils.getCategoriesAsStringList(categories),
        ParseUtils.getDynamicListAsStringList(currencies),
      )),
    );

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
        Content.multi([prompt, ...imageParts]),
      ]);

      setState(() {
        _isGenerating = false;
      });

      return GeminiUtils().validateOutput(response.text!);
    }

    return {};
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
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
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
              text: jsonData['store'],
              hintText: 'Store name',
              fontSize: 24,
              textInputType: TextInputType.text,
              onSubmitted: (newVal) {
                setState(() {
                  jsonData['store'] = newVal;
                });
              },
              onChanged: (newVal) {
                jsonData['store'] = newVal;
              },
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: "transactionScreenMini",
                key: const Key("transactionScreenMini"),
                mini: true,
                child: const Icon(Icons.add_photo_alternate_outlined),
                onPressed: () {
                  _buildModal(context);
                },
              ),
              const SizedBox(height: 15),
              FloatingActionButton(
                heroTag: "transactionScreen",
                key: const Key("transactionScreen"),
                child: const Icon(Icons.save_outlined),
                onPressed: () async {
                  try {
                    if (widget.parentJson.isNotEmpty) {
                      final DocumentReference? transactionRef =
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .collection('transactions')
                              .where('timestamp',
                                  isEqualTo: widget.parentJson['timestamp'])
                              .get()
                              .then((snapshot) {
                        if (snapshot.docs.isNotEmpty) {
                          return snapshot.docs.first.reference;
                        } else {
                          return null;
                        }
                      });
                      transactionRef!.update(jsonData);
                    } else {
                      CollectionReference transactions = FirebaseFirestore
                          .instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('transactions');

                      jsonData['timestamp'] =
                          Timestamp.fromDate(DateTime.now());
                      await transactions.add(jsonData);
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => widget.parentScreen,
                      ),
                    );
                  } catch (e) {
                    print("Error: $e");
                  }
                },
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      controller: pageController,
                      children: [
                        // _buildImagePage(),
                        _buildTransactionPage(),
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
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
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
      ),
    );
  }

  Widget _buildTransactionPage() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: jsonData.isEmpty ? 3 : jsonData['items'].length + 3,
            itemBuilder: (BuildContext context, int index) {
              if (index == jsonData['items'].length) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      jsonData['items'].add("");
                      jsonData['pieces'].add(1);
                      jsonData['prices'].add(0.0);
                    });
                  },
                  child: ListTile(
                    title: Text(
                      "Add item",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    leading: Icon(Icons.add, color: Colors.grey[700]),
                  ),
                );
              }
              if (index == jsonData['items'].length + 1) {
                return _buildBottomColumn();
              }
              if (index == jsonData['items'].length + 2) {
                return Container(height: 150);
              }
              return _buildItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomColumn() {
    return Column(
      children: [
        //! TOTAL
        Container(
          color: Colors.purple[300]!.withOpacity(0.5),
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
          child: Row(
            children: [
              const Text(
                "TOTAL",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Visibility(
                visible: _hasChangedAmountOrPrice,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      List<dynamic> pieces = jsonData["pieces"];
                      List<dynamic> prices = jsonData["prices"];

                      double sum = 0;
                      for (int i = 0; i < prices.length; i++) {
                        dynamic piece = pieces[i];
                        dynamic price = prices[i];
                        sum += (piece.toDouble() * price.toDouble());
                      }

                      jsonData['total_price'] = sum;
                      _hasChangedAmountOrPrice = false;
                    });
                  },
                  icon: Icon(Icons.refresh, color: Colors.blue[400]),
                ),
              ),
              const Spacer(flex: 1),
              SizedBox(
                  width: 100,
                  child: MyTextField(
                    text: jsonData['total_price'].toStringAsFixed(2),
                    hintText: 'Total',
                    fontSize: 22,
                    onSubmitted: (newVal) {
                      setState(() {
                        jsonData['total_price'] =
                            ParseUtils.parseDoubleFromString(newVal);
                      });
                    },
                    onChanged: (newVal) {
                      jsonData['total_price'] =
                          ParseUtils.parseDoubleFromString(newVal);
                    },
                  )),
              const SizedBox(width: 10),
              _buildCurrencyMenu()
            ],
          ),
        ),
        //! PAYMENT
        Container(
          color: Colors.purple[300]!.withOpacity(0.5),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
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
        ),
        //! CATEGORY
        Container(
          color: Colors.purple[300]!.withOpacity(0.5),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Row(
            children: [
              const Text(
                "Category",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              const Spacer(flex: 1),
              const SizedBox(width: 10),
              _buildCategoryMenu(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(int index) {
    return InkWell(
      onTap: () {},
      child: ListTile(
        tileColor: index % 2 == 0
            ? Colors.transparent
            : Colors.purple[100]!.withOpacity(0.5),
        subtitle: MyTextField(
          text: jsonData['items'][index],
          hintText: 'Item',
          textInputType: TextInputType.text,
          onSubmitted: (newVal) {
            setState(() {
              jsonData['items'][index] = newVal;
            });
          },
          onChanged: (newVal) {
            jsonData['items'][index] = newVal;
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 75,
              child: MyTextField(
                text: (ParseUtils.parseDoubleFromString(
                        jsonData['pieces'][index].toString()))
                    .toStringAsFixed(
                  jsonData['pieces'][index] % 1 == 0 ? 0 : 2,
                ),
                // textAlign: TextAlign.end,
                hintText: "Amount",
                onSubmitted: (newVal) {
                  double cleanedVal = ParseUtils.parseDoubleFromString(
                      newVal.replaceAll("x", ""));

                  if (cleanedVal == 0.0) {
                    cleanedVal = 1.0;
                  }

                  setState(() {
                    jsonData['pieces'][index] = cleanedVal;
                    _hasChangedAmountOrPrice = true;
                  });
                },
                onChanged: (newVal) {
                  double cleanedVal = ParseUtils.parseDoubleFromString(
                      newVal.replaceAll("x", ""));

                  if (cleanedVal == 0.0) {
                    cleanedVal = 1.0;
                  }

                  jsonData['pieces'][index] = cleanedVal;
                  _hasChangedAmountOrPrice = true;
                },
              ),
            ),
            const Text("x"),
            SizedBox(
              width: 100,
              child: MyTextField(
                text: (jsonData['prices'][index].toString()),
                hintText: "Price",
                onSubmitted: (newVal) {
                  setState(() {
                    jsonData['prices'][index] =
                        ParseUtils.parseDoubleFromString(newVal);
                    _hasChangedAmountOrPrice = true;
                  });
                },
                onChanged: (newVal) {
                  jsonData['prices'][index] =
                      ParseUtils.parseDoubleFromString(newVal);
                  _hasChangedAmountOrPrice = true;
                },
              ),
            ),
            const Spacer(flex: 1),
            IconButton(
              onPressed: () {
                setState(() {
                  jsonData['items'].removeAt(index);
                  jsonData['prices'].removeAt(index);
                  jsonData['pieces'].removeAt(index);
                  _hasChangedAmountOrPrice = true;
                });
              },
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyMenu() {
    return DropdownButton(
      value: jsonData['currency'].isEmpty ||
              !currencies.contains(jsonData['currency'])
          ? currencies.first
          : jsonData['currency'].toLowerCase(),
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
            jsonData['currency'] = value.toString();
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

  Future<void> _showNewCategoryDialog() async {
    String? newType;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            onChanged: (value) {
              newType = value;
            },
            decoration: const InputDecoration(
              hintText: 'Enter new category',
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
                if (newType != null && newType!.isNotEmpty) {
                  final newCategory = {
                    'codepoint': Icons.add.codePoint,
                    'colorValue': Colors.grey.value,
                    'type': newType,
                  };
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({
                    'categories': FieldValue.arrayUnion([newCategory])
                  }).then((value) {
                    setState(() {
                      categories.add(newCategory);
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
              onPressed: () async {
                if (newCurrency != null && newCurrency!.isNotEmpty) {
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .get();

                  List<double> monthlyAllowance = [];
                  for (int i = 0;
                      i < userDoc['monthly_allowance'].length;
                      i++) {
                    monthlyAllowance.add(ParseUtils.parseDoubleFromString(
                        userDoc['monthly_allowance'][i].toString()));
                  }
                  monthlyAllowance.add(1000);

                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.uid)
                      .update({
                    'currencies': FieldValue.arrayUnion([newCurrency]),
                    'monthly_allowance': monthlyAllowance
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

  Widget _buildCategoryMenu() {
    return DropdownButton(
      value: jsonData['category'],
      alignment: Alignment.center,
      style: const TextStyle(
        fontSize: 22,
        color: Colors.black,
      ),
      onChanged: (value) {
        if (value == 'Add New Category') {
          _showNewCategoryDialog();
        } else {
          setState(() {
            jsonData['category'] = value.toString();
          });
        }
      },
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text(''),
        ),
        for (dynamic category in categories)
          DropdownMenuItem(
            value: category['type'],
            child: Text(category['type']),
          ),
        const DropdownMenuItem(
          value: 'Add New Category',
          child: Text('+ New'),
        ),
      ],
    );
  }

  Widget _buildPaymentMenu() {
    return DropdownButton(
      value: jsonData['payment'].isEmpty
          ? paymentTypes.first
          : jsonData['payment'],
      alignment: Alignment.center,
      style: const TextStyle(
        fontSize: 20,
        color: Colors.black,
      ),
      onChanged: (value) {
        setState(() {
          jsonData['payment'] = value.toString();
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

  void _buildModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: _buildImageList(setState),
              floatingActionButton: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Visibility(
                    visible: erroneousFileIndices.isNotEmpty,
                    child: FloatingActionButton(
                      heroTag: "imageButtonMini",
                      key: const Key("imageButtonMini"),
                      mini: true,
                      onPressed: () {
                        for (int i = 0; i < erroneousFileIndices.length; i++) {
                          files.removeAt(erroneousFileIndices[i]);
                        }
                        erroneousFileIndices = [];
                        setState(() {});
                      },
                      child: const Icon(Icons.delete_outline),
                    ),
                  ),
                  const SizedBox(height: 15),
                  FloatingActionButton(
                    heroTag: "imageButton",
                    key: const Key("imageButton"),
                    onPressed: () async {
                      if (files.isEmpty) {
                        return;
                      }

                      if(kIsWeb) {
                        Navigator.of(context).pop();
                        Map<String, dynamic> output = await sendFilesToAI(files);
                        jsonData = mergeMaps(jsonData, output);

                        return;
                      }

                      List<String> imageToTextList = [];
                      List<XFile?> filteredImages = [];
                      setState(() {
                        erroneousFileIndices = [];
                      });
                      for (int i = 0; i < files.length; i++) {
                        final text = await getImageToText(files[i]!.path);
                        if (text.isNotEmpty) {
                          filteredImages.add(files[i]);
                          imageToTextList.add(text);
                        } else {
                          erroneousFileIndices.add(i);
                        }
                      }
                      if (erroneousFileIndices.isNotEmpty) {
                        setState(() {});
                      }

                      if (imageToTextList.isNotEmpty) {
                        Navigator.of(context).pop();
                        Map<String, dynamic> output = await sendPromptToAI(
                          imageToTextList.toString(),
                        );
                        jsonData = mergeMaps(jsonData, output);
                      }
                    },
                    child: const Icon(Icons.auto_awesome),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Map<String, dynamic> mergeMaps(
      Map<String, dynamic> map1, Map<String, dynamic> map2) {
    Map<String, dynamic> combinedMap = {};

    for (String key in map1.keys) {
      if (map1[key] is List && map2[key] is List) {
        combinedMap[key] = [...map1[key], ...map2[key]];
      } else {
        combinedMap[key] = map2[key];
      }
    }
    return combinedMap;
  }

  Widget _buildImageList(Function(void Function()) setState) {
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
              () async {
                await pickImageFromCamera();
                setState(() {});
              },
            );
          }
          if (index == files.length + 1) {
            return buildEmptyTile(
              Icons.add_photo_alternate_outlined,
              () async {
                await pickImageFromGallery();
                setState(() {});
              },
            );
          }

          return Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                    ? Image.network(
                        files[index]!.path,
                        width: double.maxFinite,
                        height: double.maxFinite,
                        fit: BoxFit.fill,
                      )
                    : Image.file(
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
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: erroneousFileIndices.contains(index)
                            ? Colors.red
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  onTap: () {
                    showDeleteDialog(
                      context: context,
                      titleText: "Delete transaction",
                      actionText: "Delete",
                      onPressed: () {
                        setState(() {
                          files.removeAt(index);
                          erroneousFileIndices.remove(index);
                        });
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
              Visibility(
                visible: erroneousFileIndices.contains(index),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      "No text detected!",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget buildEmptyTile(IconData iconData, Function() onPressed) {
    return Container(
      width: 125,
      height: 150,
      padding: const EdgeInsets.all(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: Colors.grey[300],
            ),
          ),
          Center(child: Icon(iconData)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.black.withOpacity(0.25),
              onTap: () => onPressed(),
            ),
          ),
        ],
      ),
    );
  }
}
