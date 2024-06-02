import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/CustomSnackBar.dart';
import '../fin_screen.dart';
import 'InputFormWidget.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _signInWithEmailAndPassword(String email, String pwd) async {
    try {
      CustomSnackBar.show(
        context,
        "Signing you in...",
        duration: const Duration(seconds: 60),
      );

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: pwd,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FinScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        CustomSnackBar.show(context, "User not found!");
      } else if (e.code == 'wrong-password') {
        CustomSnackBar.show(context, "Email or password is incorrect!");
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
              actionText: "Login",
              textButton: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignupScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Create an account',
                ),
              ),
              signInCallback: (String email, String pwd) {
                _signInWithEmailAndPassword(email, pwd);
              },
            ),
          ),
        ),
      ),
    );
  }
}
