import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
  double get lineTotal => product.price * quantity;
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (s, i) => s + i.quantity);

  double get subtotal => _items.fold(0, (s, i) => s + i.lineTotal);
  double get deliveryFee => isEmpty ? 0 : 500;
  double get total => subtotal + deliveryFee;

  // Returns true if item was added, false if out of stock
  bool addItem(ProductModel product) {
    if (!product.inStock) return false;
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      if (_items[idx].quantity >= product.stockQuantity) return false;
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
    return true;
  }

  void decrement(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx < 0) return;
    if (_items[idx].quantity > 1) {
      _items[idx].quantity--;
    } else {
      _items.removeAt(idx);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int quantityOf(String productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    return idx >= 0 ? _items[idx].quantity : 0;
  }
}
