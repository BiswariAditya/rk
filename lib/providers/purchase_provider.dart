import 'package:flutter/material.dart';

import '../models/purchseItem.dart';

class PurchaseProvider with ChangeNotifier {
  List<PurchaseItem> _items = [];

  List<PurchaseItem> get items => _items;

  double get subtotal {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get cgst {
    return _items.fold(0, (sum, item) => sum + (item.taxAmount / 2));
  }

  double get sgst {
    return _items.fold(0, (sum, item) => sum + (item.taxAmount / 2));
  }

  double get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.amount);
  }

  void addItem(PurchaseItem item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearPurchase() {
    _items.clear();
    notifyListeners();
  }

  void updateItem(int index, PurchaseItem item) {
    if (index >= 0 && index < _items.length) {
      _items[index] = item;
      notifyListeners();
    }
  }
}