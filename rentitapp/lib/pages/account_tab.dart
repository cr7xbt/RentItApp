import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFAFAF7), // Off White Background
      appBar: AppBar(
        title: Text('Account', style: TextStyle(color: Colors.white)), // Changed font color to white
        backgroundColor: Color(0xFFB55239), // Clay Red
        iconTheme: IconThemeData(color: Color(0xFF5A6A89)),
      ),
      body: ListView(
        children: [
          _buildListItem(context, 'Profile'),
          _buildDivider(),
          _buildListItem(context, 'Addresses'),
          _buildDivider(),
          _buildListItem(context, 'Payment Methods'),
          _buildDivider(),
          _buildListItem(context, 'Notifications'),
          _buildDivider(),
          _buildListItem(context, 'Help'),
          _buildDivider(),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB55239), // Clay Red
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(BuildContext context, String title) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: Color(0xFF5A6A89)), // Lighter Indigo Dye
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFFC1A87D)), // Brass Gold
      onTap: () {}, // Placeholder for navigation
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Color(0xFFF4E3D7), // Sandalwood Beige
      thickness: 1,
      height: 1,
    );
  }
}