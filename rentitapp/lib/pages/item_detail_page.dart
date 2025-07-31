import 'package:flutter/material.dart';
import 'package:getwidget/getwidget.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../models/shop_item_model.dart'; // Ensure the correct model is imported

class ItemDetailPage extends StatefulWidget {
  final ShopItemModel item;

  const ItemDetailPage({super.key, required this.item});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int _currentIndex = 0;
  double _rating = 0.0; // Initialize with a default value

  bool _isLoadingRating = true; // Add a loading state

  int _quantity = 0; // Initialize quantity as 0 to show "Add to Cart" initially

  @override
  void initState() {
    super.initState();
    _fetchRating(); // Fetch the rating when the page initializes
  }

  Future<void> _fetchRating() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('items')
        .select('rating')
        .eq('item_id', widget.item.itemId) // Correct column name to match Supabase schema
        .single();

    setState(() {
      if (response != null && response['rating'] != null) {
        _rating = response['rating'];
      } else {
        _rating = 0.0; // Default to 0 if no rating is found
      }
      _isLoadingRating = false; // Update loading state
    });
  }

  void _addToCart() {
    setState(() {
      _quantity = 1; // Set quantity to 1 when first adding to cart
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.item.name} added to cart'),
      ),
    );
  }

  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > 0) {
        _quantity--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GFAppBar(
        title: Text(widget.item.name),
        backgroundColor: Color(0xFF078BDC), // Set AppBar color to match the theme
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Item Image Section
          SizedBox(
            height: MediaQuery.of(context).size.height / 3,
            child: Stack(
              children: [
                GFCarousel(
                  items: [
                    AspectRatio(
                      aspectRatio: 16 / 9, // Maintain a consistent aspect ratio
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          widget.item.imageUrl ?? '',
                          fit: BoxFit.contain, // Ensure the image is not stretched
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey,
                              child: Icon(Icons.image, color: Colors.white),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                  autoPlay: true,
                  viewportFraction: 1.0,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(1, (index) {
                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentIndex == index ? 12.0 : 8.0,
                        height: _currentIndex == index ? 12.0 : 8.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index ? Colors.blue : Colors.grey,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // Display item details using widget.item
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Description:',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.0),
                Text(
                  widget.item.description?.toString() ?? 'No description available',
                  style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                ),
                SizedBox(height: 8.0),
                Text(
                  'Price: ₹${widget.item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 16.0),
                Row(
                  children: [
                    Text(
                      'Rating:',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8.0),
                    _isLoadingRating
                        ? CircularProgressIndicator() // Show loading indicator
                        : Row(
                            children: List.generate(5, (index) {
                              final rating = _rating;
                              final icon = index < rating
                                  ? Icons.star
                                  : (index < rating + 0.5 ? Icons.star_half : Icons.star_border);
                              return Icon(icon, color: Colors.amber, size: 20);
                            }),
                          ),
                    SizedBox(width: 8.0),
                    _isLoadingRating
                        ? Text('Loading...', style: TextStyle(fontSize: 16.0, color: Colors.grey[700]))
                        : Text(
                            _rating.toStringAsFixed(1),
                            style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
                          ),
                  ],
                ),
                SizedBox(height: 16.0),
                // Add to Cart Button Section
                _quantity == 0
                    ? SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addToCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFF5895A), // Same color as logout button
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'Add to Cart',
                            style: TextStyle(
                              fontSize: 18.0, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFF5895A), width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Color(0xFFF5895A)),
                              onPressed: _decrementQuantity,
                            ),
                            Text(
                              '$_quantity',
                              style: TextStyle(
                                fontSize: 18.0, 
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF5895A),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Color(0xFFF5895A)),
                              onPressed: _incrementQuantity,
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          // Removed the bottom cart section since it's now placed below ratings
        ],
      ),
    );
  }
}