class ShopItemModel {
  final int itemId;
  final int shopId;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? category;
  final String? imageUrl;
  final DateTime createdAt;

  ShopItemModel({
    required this.itemId,
    required this.shopId,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.category,
    this.imageUrl,
    required this.createdAt,
  });

  // Factory method to create a ShopItemModel from a map
  factory ShopItemModel.fromMap(Map<String, dynamic> map) {
    return ShopItemModel(
      itemId: map['item_id'],
      shopId: map['shop_id'],
      name: map['name'],
      description: map['description'],
      price: map['price'],
      stockQuantity: map['stock_quantity'],
      category: map['category'],
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}