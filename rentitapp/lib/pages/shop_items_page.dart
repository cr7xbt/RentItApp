import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shop_item_model.dart';
import '../models/shop_model.dart';

class ShopItemsPage extends StatefulWidget {
  final ShopModel shop;

  ShopItemsPage({required this.shop});

  @override
  _ShopItemsPageState createState() => _ShopItemsPageState();
}

class _ShopItemsPageState extends State<ShopItemsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<ShopItemModel> items = [];
  bool isLoading = true;
  final List<ShopItemModel> cartItems = []; // List to store cart items

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    try {
      final response = await supabase
          .from('items')
          .select('item_id, shop_id, name, description, price, stock_quantity, category, image_url, created_at')
          .eq('shop_id', widget.shop.id);

      final data = response as List<dynamic>; // Cast response to a List
      setState(() {
        items = data.map((item) => ShopItemModel.fromMap(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      // Handle any errors
      print('Error fetching items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void addToCart(ShopItemModel item) {
    setState(() {
      cartItems.add(item);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item.name} added to cart!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.shop.name}')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16), // Rounded edges
                    ),
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              item.imageUrl ?? '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 120,
                                  height: 120,
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
                                  item.name,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  item.description ?? '',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '₹${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Stock: ${item.stockQuantity}',
                                  style: TextStyle(fontSize: 14),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Category: ${item.category ?? 'N/A'}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => addToCart(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}