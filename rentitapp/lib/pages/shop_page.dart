import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:collection/collection.dart';
import 'package:video_player/video_player.dart';

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
  List<ShopItemModel> filteredItems = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  late VideoPlayerController _videoController;
  bool _isVideoLoading = true;
  bool _showVideoControls = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
    _searchController.addListener(_onSearchChanged);
    _initializeVideoPlayer();
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

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.network(
      'https://lopugfofldvdgnnxmmok.supabase.co/storage/v1/object/public/shop-videos//village_artisan_peacock.mp4',
    )
      ..initialize().then((_) {
        setState(() {
          _isVideoLoading = false;
        });
      })
      ..setLooping(true);
  }

  void _hideControlsAfterDelay() {
    Future.delayed(Duration(seconds: 1), () {
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(
          videoController: _videoController,
        ),
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
        body: Column(
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
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Story Tab
                  SingleChildScrollView(
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
                                  height: MediaQuery.of(context).size.width * 0.36, // 60% of original height (40% reduction)
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
                                        // Play/Pause button with fade animation
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
                                        // Full screen button with fade animation
                                        AnimatedOpacity(
                                          opacity: _showVideoControls ? 1.0 : 0.0,
                                          duration: Duration(milliseconds: 300),
                                          child: Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () {
                                                _openFullScreenVideo();
                                              },
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
                            'About the Shop',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This shop has a rich history of providing quality products and services to its customers. Established in 1990, it has grown to become a trusted name in the community.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Highlights',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('• High-quality products'),
                              Text('• Excellent customer service'),
                              Text('• Affordable pricing'),
                              Text('• Convenient location'),
                              Text('• Trusted by the community'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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

  const FullScreenVideoPlayer({required this.videoController, Key? key}) : super(key: key);

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _hideControlsAfterDelay();
  }

  void _hideControlsAfterDelay() {
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.videoController.value.aspectRatio,
                child: VideoPlayer(widget.videoController),
              ),
            ),
            if (_showControls) ...[
              // Top bar with back button
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
              // Center play/pause button
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.videoController.value.isPlaying
                          ? widget.videoController.pause()
                          : widget.videoController.play();
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.videoController.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
              // Bottom controls
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
