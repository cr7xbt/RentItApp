import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/state_model.dart';
import '../models/shop_model.dart';
import 'shop_items_page.dart';

class ShopListPage extends StatefulWidget {
  final StateModel state;

  ShopListPage({required this.state});

  @override
  _ShopListPageState createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<ShopModel> shops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  Future<void> fetchShops() async {
    try {
      final data = await supabase
          .from('shops')
          .select('shop_id, name, description, latitude, longitude, location, image_url, contact_number, email')
          .eq('state', widget.state.name.toLowerCase());

      if (data != null && data is List) {
        setState(() {
          shops = data.map((shop) => ShopModel(
            id: shop['shop_id'],
            name: shop['name'],
            description: shop['description'],
            latitude: shop['latitude'],
            longitude: shop['longitude'],
            location: shop['location'],
            imageUrl: shop['image_url'],
            contactNumber: shop['contact_number'],
            email: shop['email'],
          )).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching shops: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Shops in ${widget.state.name}')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 1, // Number of columns
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 3 / 2, // Aspect ratio of the grid items
                ),
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  ShopModel shop = shops[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShopItemsPage(shop: shop)),
                      );
                    },
                    child: Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16), // Rounded edges for the card
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: Image.network(
                              shop.imageUrl ?? '',
                              width: double.infinity,
                              height: 140, // Increased height of the image
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 140,
                                  color: Colors.grey,
                                  child: Icon(Icons.image, color: Colors.white),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              shop.name,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              shop.description ?? '',
                              style: TextStyle(fontSize: 14),
                            ),
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