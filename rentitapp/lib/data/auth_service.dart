import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<void> saveUserToSupabase() async {
    try {
      // Get the current Firebase user
      firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in.');
      }

      // Extract user details
      String email = firebaseUser.email ?? '';
      String displayName = firebaseUser.displayName ?? '';
      List<String> nameParts = displayName.split(' ');
      String firstName = nameParts.isNotEmpty ? nameParts[0] : '';
      String lastName = nameParts.length > 1 ? nameParts[1] : '';

      // Save user data to Supabase
      final response = await _supabaseClient.from('users').insert({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'login_status': true,
      }).execute();

      if (response.status != 204) {
        throw Exception('Failed to save user to Supabase: ${response.toString()}');
      }
    } catch (e) {
      print('Error saving user to Supabase: $e');
    }
  }

  Future<void> updateLoginStatus(bool isLoggedIn) async {
    try {
      // Get the current Firebase user
      firebase_auth.User? firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in.');
      }

      // Update login status in Supabase
      final response = await _supabaseClient.from('users').update({
        'login_status': isLoggedIn,
      }).eq('email', firebaseUser.email).execute();

      if (response.status != 204) {
        throw Exception('Failed to update login status: ${response.toString()}');
      }
    } catch (e) {
      print('Error updating login status: $e');
    }
  }
}

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveSecret(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getSecret(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteSecret(String key) async {
    await _storage.delete(key: key);
  }
}