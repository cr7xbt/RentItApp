import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/login_page.dart';
import '../pages/orders_page.dart'; // Import the OrdersPage
import '../pages/address_page.dart'; // Import the AddressPage
import 'package:getwidget/getwidget.dart';

class AccountTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Changed page background color to white
      appBar: AppBar(
        title: Text('Account', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF078BDC), // Updated header background color to #35CAFE
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
                backgroundColor: Color(0xFFF5895A), // Saffron color for logout button
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // Rounded corners for a professional look
                ),
                elevation: 5, // Add shadow for a professional look
              ),
              child: Text(
                'Logout',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
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
    return GFListTile(
      titleText: title,
      icon: Icon(Icons.arrow_forward_ios, color: Color(0xFFC1A87D)), // Brass Gold
      onTap: onTap ?? () {},
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.grey.shade300,
      thickness: 1,
      height: 1,
    );
  }
}