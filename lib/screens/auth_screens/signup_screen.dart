import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/CustomSnackBar.dart';
import '../fin_screen.dart';
import 'InputFormWidget.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  Future<void> _signUpWithEmailAndPassword(String email, String pwd) async {
    try {
      CustomSnackBar.show(
        context,
        "Signing you in...",
        duration: const Duration(seconds: 60),
      );

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pwd,
      );

      final user = FirebaseAuth.instance.currentUser;
      final userId = user!.uid;
      final userEmail = user.email;

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Create the user data map
      final userData = {
        'uid': userId,
        'email': userEmail,
        'currencies': ["eur"],
        'monthly_allowance': 1000.0,
        'paymentTypes': ['Card', 'Cash', 'Other'],
        'categories': [
          {
            'codepoint': 58261,
            'colorValue': 4294198070, //red[400]
            'type': 'Groceries',
          },
          {
            'codepoint': 57813,
            'colorValue': 4289415100, //purple[400]
            'type': 'Transport',
          },
          {
            'codepoint': 58140,
            'colorValue': 4287458915, //brown[400]
            'type': 'Services',
          },
          {
            'codepoint': 58778,
            'colorValue': 4293673082, //pink[400]
            'type': 'Shopping',
          },
          {
            'codepoint': 57454,
            'colorValue': 4282557941, //blue[400]
            'type': 'Travel',
          },
          {
            'codepoint': 58674,
            'colorValue': 4294944550, //orange[400
            'type': 'Restaurants',
          },
          {
            'codepoint': 58117,
            'colorValue': 4294930499, //deepOrange[400]
            'type': 'Health',
          },
          {
            'codepoint': 59050,
            'colorValue': 4284922730, //green[400]
            'type': 'Entertainment',
          },
          {
            'codepoint': 57522,
            'colorValue': 4294962776, //yellow[400]
            'type': 'General',
          },
        ],
      };

      // Add the user data to Firestore
      await userDoc.set(userData);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FinScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        CustomSnackBar.show(context, "Password is too weak!");
      } else if (e.code == 'email-already-in-use') {
        CustomSnackBar.show(
            context, "An account already exists with that email!");
      } else {
        CustomSnackBar.show(context, e.message!);
      }
    } finally {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: InputFormWidget(
              actionText: "Signup",
              textButton: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Back to login',
                ),
              ),
              signInCallback: (String email, String pwd) {
                _signUpWithEmailAndPassword(email, pwd);
              },
            ),
          ),
        ),
      ),
    );
  }
}
