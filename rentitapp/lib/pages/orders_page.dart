import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class OrdersPage extends StatefulWidget {
  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> _currentOrders = [];
  List<Map<String, dynamic>> _oldOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in.');
      }

      final supabaseClient = Supabase.instance.client;
      final response = await supabaseClient
          .from('orders')
          .select('*, items(name, description, price, image_url)')
          .eq('user_email', firebaseUser.email)
          .order('created_at', ascending: false)
          .execute();

      if (response.status != 200) {
        throw Exception('Failed to fetch orders. Status code: ${response.status}');
      }

      final orders = List<Map<String, dynamic>>.from(response.data);

      setState(() {
        _currentOrders = orders
            .where((order) => order['order_status'] == 'Pending')
            .toList();
        _oldOrders = orders
            .where((order) => order['order_status'] != 'Pending')
            .toList();
      });
    } catch (e) {
      print('Error fetching orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch orders: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Orders'),
      ),
      body: ListView(
        children: [
          if (_currentOrders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Current Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._currentOrders.map((order) => _buildOrderCard(order)).toList(),
          ],
          if (_oldOrders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Old Orders',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ..._oldOrders.map((order) => _buildOrderCard(order)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final item = order['items'];
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(3.24), // Reduced by 10%
              child: Image.network(
                item['image_url'] ?? '',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey,
                    child: Icon(Icons.image, color: Colors.white),
                  );
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Unknown Item',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text('Price: \$${item['price']}'),
                  SizedBox(height: 6),
                  Text('Quantity: ${order['quantity']}'),
                  SizedBox(height: 6),
                  Text('Status: ${order['order_status']}'),
                  SizedBox(height: 6),
                  Text('Ordered on: ${_formatDate(order['created_at'])}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    final parsedDate = DateTime.parse(date);
    final daySuffix = _getDaySuffix(parsedDate.day);
    return "${_monthName(parsedDate.month)} ${parsedDate.day}$daySuffix ${parsedDate.year}";
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
