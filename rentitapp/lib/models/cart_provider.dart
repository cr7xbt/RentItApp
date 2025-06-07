import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/shop_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<ShopItemModel> _cartItems = []; // Updated to store ShopItemModel objects

  List<ShopItemModel> get cartItems => List.unmodifiable(_cartItems);

  void addItem(ShopItemModel item) {
    final existingItem = _cartItems.firstWhereOrNull(
      (cartItem) => cartItem.itemId == item.itemId,
    );

    if (existingItem != null) {
      existingItem.quantity += 1; // Increment quantity if item exists
    } else {
      item.quantity = 1; // Initialize quantity for new item
      _cartItems.add(item);
    }

    notifyListeners();
  }

  void updateItemQuantity(int itemId, int change) {
    final existingItem = _cartItems.firstWhereOrNull((item) => item.itemId == itemId);
    if (existingItem != null) {
      final newQuantity = existingItem.quantity + change;
      if (newQuantity > 0) {
        existingItem.quantity = newQuantity;
      } else {
        _cartItems.remove(existingItem); // Remove item if quantity becomes 0 or less
      }
      notifyListeners();
    }
  }

  void removeItem(String itemName) {
    _cartItems.removeWhere((item) => item.name == itemName);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
}