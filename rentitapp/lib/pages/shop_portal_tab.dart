import 'package:flutter/material.dart';
import 'shop_portal_details_page.dart';
import '../data/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class ShopPortalTab extends StatefulWidget {
  @override
  _ShopPortalTabState createState() => _ShopPortalTabState();
}

class _ShopPortalTabState extends State<ShopPortalTab> {
  List<Map<String, String>> _shops = []; // List to store shop details
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchUserShops();
  }

  void _fetchUserShops() async {
    try {
      firebase_auth.User? firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in.');
      }

      // Fetch shops associated with the logged-in user's email
      final supabaseClient = Supabase.instance.client;
      final response = await supabaseClient
          .from('shops')
          .select()
          .eq('user_email', firebaseUser.email)
          .execute();

      if (response.status != 200) {
        print (response.status);
        print (response.data);
        throw Exception('Failed to fetch shops: ${response.toString()}');
      }

      setState(() {
        _shops = List<Map<String, String>>.from(response.data.map((shop) => {
          'name': shop['name']?.toString() ?? 'Unnamed',
          'description': shop['description']?.toString() ?? '',
          'state': shop['state']?.toString() ?? '',
        }));
      });
    } catch (e) {
      print('Error fetching shops: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch shops: $e")),
      );
    }
  }

  void _navigateToAddShopPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopPortalDetailsPage(),
      ),
    );

    print("Returned shop data: $result");

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _shops.add({
          'name': result['name']?.toString() ?? 'Unnamed',
          'description': result['description']?.toString() ?? '',
          'city': result['city']?.toString() ?? '',
          'state': result['state']?.toString() ?? '',
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Portal'),
      ),
      body: _shops.isEmpty
          ? Center(
              child: Text(
                'No Shops Added',
                style: TextStyle(color: Colors.grey, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _shops.length,
              itemBuilder: (context, index) {
                final shop = _shops[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(shop['name'] ?? 'Unknown Shop'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(shop['description'] ?? 'No Description'),
                        SizedBox(height: 4),
                        Text('${shop['state']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddShopPage,
        label: Text('Add Shop'),
        icon: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}