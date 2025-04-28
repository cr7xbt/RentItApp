import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'signup_page.dart';
import '../data/auth_service.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  Future<void> loginUser(BuildContext context) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        if (user.emailVerified) {
          await _authService.updateLoginStatus(true); // Update login status in Supabase
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(user: user)),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Please verify your email before logging in.")),
          );
        }
      } else {
        throw Exception("User is null");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Image.asset(
          'assets/logo.png',
          height: 100,
        ),
        SizedBox(height: 20),
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () => loginUser(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 3, 9, 3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Login',
                style: TextStyle(fontSize: 18),
              ),
          ),
        ),
        TextButton(
          onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignupPage()),
          );
          },
          child: Text('Signup'),
        ),
        ],
      ),
      ),
    );
  }
}