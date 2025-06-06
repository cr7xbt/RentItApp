import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:getwidget/getwidget.dart';
import '../models/state_model.dart';
import '../models/shop_model.dart';
import 'shop_page.dart';

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
          .select('shop_id, name, description, latitude, longitude, location, image_url, contact_number, email, rating')
          .eq('state', widget.state.name.toLowerCase());

      if (data != null && data is List) {
        setState(() {
          shops = data.map((shop) => ShopModel.fromMap(shop)).toList();
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
      appBar: AppBar(
        title: Text(widget.state.name, style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF078BDC),
        elevation: 4.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                itemCount: shops.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                  crossAxisSpacing: 1.0, // Reduced from 16.0
                  mainAxisSpacing: 1.0, // Reduced from 16.0
                  childAspectRatio: 5 / 4, // Adjusted aspect ratio
                ),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ShopPage(shop: shop),
                        ),
                      );
                    },
                    child: GFCard(
                      elevation: 4.0,
                      padding: EdgeInsets.zero,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                            child: shop.imageUrl != null && shop.imageUrl!.isNotEmpty
                                ? Image.network(
                                    shop.imageUrl!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    'assets/logo.png',
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shop.name,
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  shop.description ?? 'No description available',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    double rating = shop.rating;
                                    IconData iconData;
                                    Color color;
                                    if (rating >= starIndex + 1) {
                                      iconData = Icons.star;
                                      color = Colors.amber;
                                    } else if (rating > starIndex && rating < starIndex + 1) {
                                      iconData = Icons.star_half;
                                      color = Colors.amber;
                                    } else {
                                      iconData = Icons.star_border;
                                      color = Colors.grey;
                                    }
                                    return Icon(iconData, color: color, size: 16);
                                  })
                                  ..add(SizedBox(width: 4))
                                  ..add(Text(
                                    shop.rating.toStringAsFixed(1),
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  )),
                                ),
                              ],
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