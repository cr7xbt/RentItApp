import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'cart_tab.dart'; // Updated import from orders_tab.dart to cart_tab.dart
import 'account_tab.dart';
import 'state_selection_page.dart';
import 'products_tab.dart';
import 'shop_portal_tab.dart'; // Import the shop portal tab
import '../data/auth_service.dart';
import 'package:provider/provider.dart';
import '../models/cart_provider.dart';
import 'package:getwidget/getwidget.dart';

class HomePage extends StatefulWidget {
  final User user;

  HomePage({required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Updated length to 2
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> logoutUser(BuildContext context) async {
    try {
      await _authService.updateLoginStatus(false); // Update login status in Supabase
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItemCount = Provider.of<CartProvider>(context).cartItems.length;

    final List<Widget> _pages = <Widget>[
      Scaffold(
        appBar: GFAppBar(
          backgroundColor: Color(0xFF078BDC), // Set background color to light blue
          title: Row(
            children: [
              Image.asset(
                'assets/logo.png', // Replace with your logo image path
                height: 50, // Adjust the height as needed
              ),
              SizedBox(width: 8), // Add spacing between logo and title if needed
              Text(
                'Home',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white, // Set tab text color to white
            unselectedLabelColor: Colors.white70, // Slightly dimmed white for unselected tabs
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'States'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ProductsTab(),
            StateSelectionPage(),
          ],
        ),
      ),
      CartTab(), // Updated reference from OrdersTab to CartTab
      ShopPortalTab(), // Added Shop Portal Tab
      AccountTab(),
    ];

    return Scaffold(
      body: Center(
        child: _pages.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (cartItemCount > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(1.4), // Reduced padding for smaller badge
                      decoration: BoxDecoration(
                        color: Colors.green, // Changed color to green
                        borderRadius: BorderRadius.circular(7), // Adjusted for smaller size
                      ),
                      constraints: BoxConstraints(
                        minWidth: 11.2, // Reduced width for smaller badge
                        minHeight: 11.2, // Reduced height for smaller badge
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8.4, // Reduced font size for smaller badge
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Shops',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}