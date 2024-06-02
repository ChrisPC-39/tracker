import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';

import '../widgets/GeminiUtils.dart';

class GetPictureTextScreen extends StatefulWidget {
  const GetPictureTextScreen({Key? key}) : super(key: key);

  @override
  State<GetPictureTextScreen> createState() => _GetPictureTextScreenState();
}

class _GetPictureTextScreenState extends State<GetPictureTextScreen> {
  final ImagePicker picker = ImagePicker();
  bool _isGenerating = false;
  List<XFile?> files = [];
  List<String> errors = [];
  String tmpString = "";

  Future<void> sentPromptToAI(List<XFile?> files) async {
    final GeminiUtils geminiUtils = GeminiUtils();
    final model = FirebaseVertexAI.instance.generativeModel(
      model: GeminiUtils.model,
      systemInstruction: Content.system(geminiUtils.getFinInstructions([], [])),
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
        Content.multi([prompt, ...imageParts])
      ]);

      setState(() {
        _isGenerating = false;
      });

      try {
        Map<String, dynamic> jsonData = jsonDecode(response.text!);

        // Access the extracted information
        String storeName = jsonData['store'];
        List<String> itemsBought = List<String>.from(jsonData['items']);
        // ... and so on

        setState(() {
          tmpString = jsonData.toString();
        });
      } catch (e) {
        print('Error parsing JSON: $e');
        // Handle potential parsing errors if the model's output is not valid JSON
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              pickImageFromCamera();
            },
            child: const Text("Take pic"),
          ),
          TextButton(
            onPressed: () {
              pickImageFromGallery();
            },
            child: const Text("Select pics"),
          ),
          Visibility(
            visible: files.isNotEmpty,
            child: const Text("FILE LOADED"),
          ),
          TextButton(
            onPressed: () async {
              setState(() {
                errors = [];
                if(files.isEmpty) {
                  errors = ["No files found"];
                }
              });
              List<XFile?> filteredImages = [];

              for (int i = 0; i < files.length; i++) {
                final text = await getImageToText(files[i]!.path);
                if (text.isNotEmpty) {
                  filteredImages.add(files[i]);
                } else {
                  errors.add(
                      "No text detected in file: ${i + 1} : ${files[i]!.name}");
                }
              }
              if (filteredImages.isNotEmpty) {
                sentPromptToAI(filteredImages);
              }
            },
            child: const Text("AI"),
          ),
          _isGenerating
              ? const Center(child: CircularProgressIndicator())
              : Text(tmpString),
          Expanded(
            child: ListView.builder(
              itemCount: errors.length,
              itemBuilder: (errorContext, errorIndex) {
                final error = errors[errorIndex];
                return Text(error);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future pickImageFromGallery() async {
    final List<XFile?> pickedImages = await picker.pickMultiImage();

    if (pickedImages.isEmpty) {
      return;
    }

    setState(() {
      files = pickedImages;
    });
  }

  Future pickImageFromCamera() async {
    final XFile? pickedImage = await ImagePicker.platform
        .getImageFromSource(source: ImageSource.camera);

    if (pickedImage == null) {
      return;
    }

    setState(() {
      files = [pickedImage];
    });
  }

  Future<String> getImageToText(final imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(InputImage.fromFilePath(imagePath));
    String text = recognizedText.text.toString();
    return text;
  }
}
