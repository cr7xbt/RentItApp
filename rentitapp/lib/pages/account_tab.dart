import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/login_page.dart';
import '../pages/orders_page.dart'; // Import the OrdersPage
import '../pages/address_page.dart'; // Import the AddressPage

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
          _buildListItem(context, 'Addresses', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddressPage()),
            );
          }),
          _buildDivider(),
          _buildListItem(context, 'Payment Methods'),
          _buildDivider(),
          _buildListItem(context, 'Notifications'),
          _buildDivider(),
          _buildListItem(context, 'Help'),
          _buildDivider(),
          _buildListItem(context, 'Orders', onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => OrdersPage()),
            );
          }),
          _buildDivider(),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: () => _logoutUser(context),
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

  void _logoutUser(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Widget _buildListItem(BuildContext context, String title, {VoidCallback? onTap}) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 16, color: Color(0xFF5A6A89)), // Lighter Indigo Dye
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFFC1A87D)), // Brass Gold
      onTap: onTap ?? () {}, // Use the provided onTap or default to an empty function
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