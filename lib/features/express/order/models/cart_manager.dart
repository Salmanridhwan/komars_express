import 'package:flutter/foundation.dart';
import '../../menu/models/menu_item_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get subtotal => menuItem.price * quantity;
}

class CartManager {
  CartManager._();
  static final CartManager instance = CartManager._();

  final List<CartItem> _items = [];
  final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  List<CartItem> get items => List.unmodifiable(_items);

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.subtotal;
    }
    return total;
  }

  int get totalCount {
    int count = 0;
    for (var item in _items) {
      count += item.quantity;
    }
    return count;
  }

  void addItem(MenuItemModel item) {
    final existingIdx = _items.indexWhere((element) => element.menuItem.id == item.id);
    if (existingIdx >= 0) {
      _items[existingIdx].quantity++;
    } else {
      _items.add(CartItem(menuItem: item));
    }
    _notify();
  }

  void removeItem(MenuItemModel item) {
    _items.removeWhere((element) => element.menuItem.id == item.id);
    _notify();
  }

  void decrementItem(MenuItemModel item) {
    final existingIdx = _items.indexWhere((element) => element.menuItem.id == item.id);
    if (existingIdx >= 0) {
      if (_items[existingIdx].quantity > 1) {
        _items[existingIdx].quantity--;
      } else {
        _items.removeAt(existingIdx);
      }
    }
    _notify();
  }

  void clear() {
    _items.clear();
    _notify();
  }

  void _notify() {
    cartCountNotifier.value = totalCount;
  }
}
