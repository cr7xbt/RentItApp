import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is initialized
  await Firebase.initializeApp(); // Initializes Firebase
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lopugfofldvdgnnxmmok.supabase.co', // Replace with your Supabase URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvcHVnZm9mbGR2ZGdubnhtbW9rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzkwMzYwMDksImV4cCI6MjA1NDYxMjAwOX0.TVtJXo8oyyWpBV70bOvy_rSOU3IEh2bARoWrn41qhDY', // Replace with your Supabase anon key
  );
  runApp(RentItApp());
}

class RentItApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rent It App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LoginPage(), // Start with the Login Page
    );
  }
}