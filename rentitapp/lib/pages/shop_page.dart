import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:collection/collection.dart';
import 'package:video_player/video_player.dart';

import '../models/shop_item_model.dart';
import '../models/shop_model.dart';
import '../models/cart_provider.dart';
import 'item_detail_page.dart';

class ShopPage extends StatefulWidget {
  final ShopModel shop;

  ShopPage({required this.shop});

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<ShopItemModel> items = [];
  List<ShopItemModel> filteredItems = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  late VideoPlayerController _videoController;
  bool _isVideoLoading = true;
  bool _showVideoControls = true;

  Map<String, dynamic>? storyData;

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchStory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncCartWithShopPage();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _videoController.dispose();
    super.dispose();
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
        filteredItems = items;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchStory() async {
    try {
      final response = await supabase
          .from('stories')
          .select()
          .eq('shop_id', widget.shop.id)
          .single();

      setState(() {
        storyData = response;
        if (storyData != null && storyData!['video_url'] != null) {
          _initializeVideoPlayer(storyData!['video_url']);
        }
      });
    } catch (e) {
      print('Error fetching story: $e');
    }
  }

  void syncCartWithShopPage() {
    final cartProvider = provider.Provider.of<CartProvider>(context, listen: true);
    final cartItems = cartProvider.cartItems;

    setState(() {
      for (var cartItem in cartItems) {
        final shopItem = items.firstWhereOrNull((item) => item.itemId == cartItem.itemId);
        if (shopItem != null) {
          shopItem.quantity = cartItem.quantity;
        }
      }
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredItems = items;
      } else {
        filteredItems = items.where((item) {
          return item.name.toLowerCase().contains(query) ||
              item.description?.toLowerCase().contains(query) == true ||
              item.category?.toLowerCase().contains(query) == true;
        }).toList();
      }
    });
  }

  void addToCart(ShopItemModel item) {
    final cartProvider = provider.Provider.of<CartProvider>(context, listen: false);
    final existingItem = cartProvider.cartItems.firstWhereOrNull((cartItem) => cartItem.itemId == item.itemId);

    if (existingItem != null) {
      cartProvider.updateItemQuantity(existingItem.itemId, existingItem.quantity + 1);
    } else {
      item.quantity = 1;
      cartProvider.addItem(item);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${item.name} added to cart!")),
    );
  }

  void _initializeVideoPlayer(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isVideoLoading = false;
        });
      })
      ..setLooping(true);
  }

  void _hideControlsAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && _videoController.value.isPlaying) {
        setState(() {
          _showVideoControls = false;
        });
      }
    });
  }

  void _toggleVideoControls() {
    setState(() {
      _showVideoControls = true;
    });
    if (_videoController.value.isPlaying) {
      _hideControlsAfterDelay();
    }
  }

  void _openFullScreenVideo() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! > 20) {
              Navigator.of(context).pop();
            }
          },
          child: ScaleTransition(
            scale: animation,
            child: FullScreenVideoPlayer(
              videoController: _videoController,
            ),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.shop.name, style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF078BDC),
          elevation: 4.0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Header Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(widget.shop.imageUrl ?? ''),
                        backgroundColor: Colors.grey[200],
                      ),
                      const SizedBox(width: 16),
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
                const SizedBox(height: 2),
                TabBar(
                  tabs: [
                    Tab(text: 'Items'),
                    Tab(text: 'Story'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Items Tab
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: TextField(
                              controller: _searchController,
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                itemCount: filteredItems.length,
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4.0,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ItemDetailPage(item: item),
                                          ),
                                        );
                                      },
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
                                                  Row(
                                                    children: [
                                                      AnimatedAddToCartButton(item: item),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Story Tab
                      buildStoryTab(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStoryTab() {
    if (storyData == null || storyData!.isEmpty) {
      return Center(
        child: Text(
          'No story added yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isVideoLoading)
              Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.width * 0.468,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: GestureDetector(
                      onTap: _toggleVideoControls,
                      child: Stack(
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: _videoController.value.aspectRatio,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _openFullScreenVideo,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.fullscreen,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: _showVideoControls ? 1.0 : 0.0,
                            duration: Duration(milliseconds: 300),
                            child: Center(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (_videoController.value.isPlaying) {
                                      _videoController.pause();
                                    } else {
                                      _videoController.play();
                                      _hideControlsAfterDelay();
                                    }
                                  });
                                },
                                child: Icon(
                                  _videoController.value.isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 64,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedOpacity(
                    opacity: _showVideoControls ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: VideoProgressIndicator(
                      _videoController,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            Text(
              storyData?['title'] ?? 'Story Title',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              storyData?['description'] ?? 'No description available.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        itemCount = 0;
      });
    });
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
        provider.Provider.of<CartProvider>(context, listen: false).updateItemQuantity(widget.item.itemId, -1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
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
                width: 140,
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
                width: 140,
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

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController videoController;

  FullScreenVideoPlayer({required this.videoController});

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;

  void _togglePlayPause() {
    setState(() {
      if (widget.videoController.value.isPlaying) {
        widget.videoController.pause();
      } else {
        widget.videoController.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: widget.videoController.value.aspectRatio,
              child: VideoPlayer(widget.videoController),
            ),
          ),
          // Play/Pause button overlay
          if (_showControls)
            Center(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Icon(
                  widget.videoController.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          // Progress bar at the bottom
          Positioned(
            bottom: 40, // Adjusted from 0 to 20 pixels
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              widget.videoController,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white.withOpacity(0.5),
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}