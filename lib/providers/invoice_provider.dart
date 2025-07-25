import 'package:flutter/material.dart';
import '../models/item.dart';

class InvoiceProvider with ChangeNotifier {
  final List<Item> _items = [];

  List<Item> get items => List.unmodifiable(_items);

  void addItem(Item item) {
    _items.add(item);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  /// Subtotal (Total before tax)
  double get subtotal => _items.fold(0, (sum, item) => sum + item.amount);

  /// Maximum tax rate among all items (as per GST rules, highest rate applies)
  double get taxRate =>
      _items.isNotEmpty ? _items.map((item) => item.taxRate).reduce((a, b) => a > b ? a : b) : 0;

  /// Total tax amount
  double get totalTax => subtotal * taxRate / 100;

  /// CGST (Half of total tax, applicable for intra-state transactions)
  double get cgst => subtotal * (taxRate / 2) / 100;

  /// SGST (Same as CGST, applicable for intra-state transactions)
  double get sgst => subtotal * (taxRate / 2) / 100;

  /// IGST (Full tax, applicable for inter-state transactions)
  double get igst => subtotal * taxRate / 100;

  /// Grand Total (Subtotal + Total Tax)
  double get totalAmount => subtotal + totalTax;

  void clearInvoice() {
    _items.clear();
    notifyListeners();
  }
}
