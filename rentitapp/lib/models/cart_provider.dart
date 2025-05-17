import 'package:flutter/foundation.dart';
import '../models/shop_item_model.dart';

class CartProvider extends ChangeNotifier {
  final List<ShopItemModel> _cartItems = []; // Updated to store ShopItemModel objects

  List<ShopItemModel> get cartItems => List.unmodifiable(_cartItems);

  void addItem(ShopItemModel item) {
    _cartItems.add(item);
    notifyListeners();
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