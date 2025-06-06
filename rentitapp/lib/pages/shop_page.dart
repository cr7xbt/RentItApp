import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:collection/collection.dart';
import '../models/shop_item_model.dart';
import '../models/shop_model.dart';
import '../models/cart_provider.dart';

class ShopPage extends StatefulWidget {
  final ShopModel shop;

  ShopPage({required this.shop});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<ShopItemModel> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
    syncCartWithShopPage();
  }

  Future<void> fetchItems() async {
    try {
      final response = await supabase
          .from('items')
          .select('item_id, shop_id, name, description, price, stock_quantity, category, image_url, created_at')
          .eq('shop_id', widget.shop.id);

      final data = response as List<dynamic>;
      setState(() {
        items = data.map((item) => ShopItemModel.fromMap(item)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void syncCartWithShopPage() {
    final cartItems = provider.Provider.of<CartProvider>(context, listen: false).cartItems;
    for (var cartItem in cartItems) {
      final shopItem = items.firstWhereOrNull((item) => item.itemId == cartItem.itemId);
      if (shopItem != null) {
        shopItem.quantity = cartItem.quantity;
      }
    }
  }

  void addToCart(ShopItemModel item) {
    provider.Provider.of<CartProvider>(context, listen: false).addItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item.name} added to cart!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shop.name, style: TextStyle(color: Colors.white)),
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
                // Header Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Shop Logo
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(widget.shop.imageUrl ?? ''),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 16),
                      // Shop Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.shop.name,
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.shop.description ?? 'No description available.',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(5, (starIndex) {
                                  double rating = widget.shop.rating;
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
                                  return Icon(iconData, color: color, size: 20);
                                }),
                                const SizedBox(width: 4),
                                Text(
                                  widget.shop.rating.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Items Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4.0,
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            height: 220,
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item.imageUrl ?? '',
                                    width: 120,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 120,
                                        height: double.infinity,
                                        color: Colors.grey,
                                        child: Icon(Icons.image, color: Colors.white),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.description ?? '',
                                            style: TextStyle(fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '₹${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                          Text('Stock: ${item.stockQuantity}'),
                                          Text('Category: ${item.category ?? 'N/A'}'),
                                        ],
                                      ),
                                      AnimatedAddToCartButton(item: item),
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
                ),
              ],
            ),
    );
  }
}

class AnimatedAddToCartButton extends StatefulWidget {
  final ShopItemModel item;

  const AnimatedAddToCartButton({required this.item, Key? key}) : super(key: key);

  @override
  _AnimatedAddToCartButtonState createState() => _AnimatedAddToCartButtonState();
}

class _AnimatedAddToCartButtonState extends State<AnimatedAddToCartButton>
    with SingleTickerProviderStateMixin {
  int itemCount = 0;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.1, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void incrementItem() {
    setState(() {
      itemCount++;
      provider.Provider.of<CartProvider>(context, listen: false).addItem(widget.item);
    });
  }

  void decrementItem() {
    setState(() {
      if (itemCount > 0) {
        itemCount--;
        provider.Provider.of<CartProvider>(context, listen: false)
            .updateItemQuantity(widget.item.itemId, itemCount); // Update quantity in cart
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48, // Set consistent height
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: itemCount == 0
            ? SizedBox(
                width: 140, // Match this width with counter width
                child: ElevatedButton(
                  key: const ValueKey("AddToCart"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5895A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    _controller.forward();
                    incrementItem();
                  },
                  child: const Text("Add to Cart"),
                ),
              )
            : SizedBox(
                key: const ValueKey("Counter"),
                width: 140, // Match width
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.orange, width: 2),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.black),
                          onPressed: decrementItem,
                        ),
                        Text(
                          "$itemCount",
                          style: const TextStyle(fontSize: 16, color: Colors.black),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.black),
                          onPressed: incrementItem,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
