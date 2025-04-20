import 'package:flutter/material.dart';
import 'shop_portal_details_page.dart';

class ShopPortalTab extends StatefulWidget {
  @override
  _ShopPortalTabState createState() => _ShopPortalTabState();
}

class _ShopPortalTabState extends State<ShopPortalTab> {
  List<Map<String, String>> _shops = []; // List to store shop details

  void _navigateToAddShopPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShopPortalDetailsPage(),
      ),
    );
    
    print("Returned shop data: $result");
    
    if (result != null && result is Map<String, dynamic>) { // **** relaxed type
      setState(() {
        _shops.add({
          'name': result['name']?.toString() ?? 'Unnamed',
          'description': result['description']?.toString() ?? '',
          'city': result['city']?.toString() ?? '',
          'state': result['state']?.toString() ?? '',
        }); // **** safely convert values to string
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
                        Text('${shop['city']}, ${shop['state']}'),
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