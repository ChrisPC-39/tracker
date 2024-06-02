import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../widgets/CustomSnackBar.dart';
import '../../widgets/AnimatedGradient.dart';
import '../../widgets/GradientThemes.dart';
import '../getPictureTextScreen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GetPictureTextScreen()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          CustomSnackBar.show(context, "User not found!");
        } else if (e.code == 'wrong-password') {
          CustomSnackBar.show(context, "Email or password is incorrect!");
        } else {
          CustomSnackBar.show(context, e.message!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(fontSize: 30),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: "Email address",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: const BorderSide(color: Colors.black)
                            )
                          ),
                          // style: const TextStyle(color: Colors.white),
                          // cursorColor: Colors.white,
                          // decoration: InputDecoration(
                          //   hintText: 'Enter your email',
                          //   hintStyle: TextStyle(
                          //     color: Colors.white.withOpacity(0.5),
                          //   ),
                          //   focusedBorder: const OutlineInputBorder(
                          //     borderSide: BorderSide(color: Colors.white),
                          //   ),
                          //   enabledBorder: OutlineInputBorder(
                          //     borderSide: BorderSide(
                          //       color: Colors.white.withOpacity(0.5),
                          //     ),
                          //   ),
                          //   focusedErrorBorder: OutlineInputBorder(
                          //     borderSide: BorderSide(color: Colors.red[300]!),
                          //   ),
                          //   errorBorder: OutlineInputBorder(
                          //     borderSide: BorderSide(color: Colors.red[300]!),
                          //   ),
                          //   errorStyle: TextStyle(color: Colors.red[300]),
                          // ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          // style: const TextStyle(color: Colors.white),
                          // cursorColor: Colors.white,
                          // decoration: InputDecoration(
                          //   hintText: 'Enter your password',
                          //   hintStyle: TextStyle(
                          //     color: Colors.white.withOpacity(0.5),
                          //   ),
                          //   focusedBorder: const OutlineInputBorder(
                          //     borderSide: BorderSide(color: Colors.white),
                          //   ),
                          //   enabledBorder: OutlineInputBorder(
                          //     borderSide: BorderSide(
                          //       color: Colors.white.withOpacity(0.5),
                          //     ),
                          //   ),
                          //   focusedErrorBorder: OutlineInputBorder(
                          //     borderSide: BorderSide(color: Colors.red[300]!),
                          //   ),
                          //   errorBorder: OutlineInputBorder(
                          //     borderSide: BorderSide(color: Colors.red[300]!),
                          //   ),
                          //   errorStyle: TextStyle(color: Colors.red[300]),
                          // ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
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
                                // style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _signInWithEmailAndPassword,
                              child: const Text('Login'),
                            ),
                          ],
                        ),

                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
