import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:getwidget/getwidget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

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
  List<ShopModel> filteredShops = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Map<int, bool> favoriteStatus = {};

  @override
  void initState() {
    super.initState();
    fetchShops();
    fetchFavoriteStatus();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
          filteredShops = shops;
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

  Future<void> fetchFavoriteStatus() async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      final response = await supabase
          .from('favorite_shops')
          .select('shop_id')
          .eq('user_email', firebaseUser.email);

      if (response != null && response is List) {
        setState(() {
          for (var favorite in response) {
            favoriteStatus[favorite['shop_id']] = true;
          }
        });
      }
    } catch (e) {
      print('Error fetching favorite status: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredShops = query.isEmpty
          ? shops
          : shops.where((shop) {
              return shop.name.toLowerCase().contains(query) ||
                  shop.description?.toLowerCase().contains(query) == true ||
                  shop.location?.toLowerCase().contains(query) == true;
            }).toList();
    });
  }

  Future<void> toggleFavorite(int shopId) async {
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;

      if (favoriteStatus[shopId] == true) {
        await supabase
            .from('favorite_shops')
            .delete()
            .eq('user_email', firebaseUser.email)
            .eq('shop_id', shopId);
      } else {
        await supabase.from('favorite_shops').insert({
          'user_email': firebaseUser.email,
          'shop_id': shopId,
        });
      }

      setState(() {
        favoriteStatus[shopId] = !(favoriteStatus[shopId] ?? false);
      });
    } catch (e) {
      print('Error toggling favorite: $e');
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search shops...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    itemCount: filteredShops.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      crossAxisSpacing: 1.0,
                      mainAxisSpacing: 1.0,
                      childAspectRatio: 5 / 4,
                    ),
                    itemBuilder: (context, index) {
                      final shop = filteredShops[index];
                      final isFavorite = favoriteStatus[shop.id] == true;

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
                          content: Stack(
                            children: [
                              Column(
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
                                          children: [
                                            ...List.generate(5, (starIndex) {
                                              final rating = shop.rating;
                                              final iconData = rating >= starIndex + 1
                                                  ? Icons.star
                                                  : rating > starIndex
                                                      ? Icons.star_half
                                                      : Icons.star_border;
                                              final color = rating >= starIndex + 1 || rating > starIndex
                                                  ? Colors.amber
                                                  : Colors.grey;
                                              return Icon(iconData, color: color, size: 20);
                                            }),
                                            SizedBox(width: 4),
                                            Text(
                                              shop.rating.toStringAsFixed(1),
                                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                top: 125,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: AnimatedSwitcher(
                                    duration: Duration(milliseconds: 300),
                                    transitionBuilder: (child, animation) => ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                    child: IconButton(
                                      key: ValueKey(isFavorite),
                                      icon: Icon(
                                        isFavorite ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorite ? Colors.red : Colors.grey,
                                      ),
                                      onPressed: () => toggleFavorite(shop.id),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}