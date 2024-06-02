import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_tracker/screens/getPictureTextScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/CustomSnackBar.dart';
import '../../widgets/AnimatedGradient.dart';
import '../../widgets/GradientThemes.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmailAndPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
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
          'currencies': [],
          'monthly_allowance': 1000,
          'paymentTypes': ['Card', 'Cash', 'None'],
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
          MaterialPageRoute(builder: (context) => const GetPictureTextScreen()),
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
            AnimatedGradient(gradientTheme: GradientTheme.loginColors),
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
                          "Sign up",
                          style: TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Email',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            errorStyle: TextStyle(color: Colors.red[300]),
                          ),
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red[300]!),
                            ),
                            errorStyle: TextStyle(color: Colors.red[300]),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _signUpWithEmailAndPassword,
                          child: const Text('Sign up'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Already have an account? Login',
                            style: TextStyle(color: Colors.white),
                          ),
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
