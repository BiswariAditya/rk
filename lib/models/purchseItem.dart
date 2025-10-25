class PurchaseItem {
  final String description;
  final double length;
  final double breadth;
  final int hsnCode;
  final int quantity;
  final double rate;
  final double taxRate;

  PurchaseItem({
    required this.description,
    required this.length,
    required this.breadth,
    required this.hsnCode,
    required this.quantity,
    required this.rate,
    required this.taxRate,
  });

  double get size => length * breadth;
  double get subtotal => size * quantity * rate;
  double get taxAmount => subtotal * (taxRate / 100);
  double get amount => subtotal + taxAmount;

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'length': length,
      'breadth': breadth,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'rate': rate,
      'taxRate': taxRate,
      'size': size,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'amount': amount,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      description: map['description'] ?? '',
      length: (map['length'] ?? 0).toDouble(),
      breadth: (map['breadth'] ?? 0).toDouble(),
      hsnCode: map['hsnCode'] ?? 0,
      quantity: map['quantity'] ?? 0,
      rate: (map['rate'] ?? 0).toDouble(),
      taxRate: (map['taxRate'] ?? 0).toDouble(),
    );
  }
}

class PurchaseBill {
  final String? id;
  final String billNumber;
  final String billDate;
  final String supplierName;
  final String supplierAddress;
  final String supplierGstNumber;
  final String supplierPhone;
  final List<PurchaseItem> items;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseBill({
    this.id,
    required this.billNumber,
    required this.billDate,
    required this.supplierName,
    required this.supplierAddress,
    required this.supplierGstNumber,
    required this.supplierPhone,
    required this.items,
    required this.totalAmount,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get subtotal {
    return items.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get cgst {
    return items.fold(0, (sum, item) => sum + (item.taxAmount / 2));
  }

  double get sgst {
    return items.fold(0, (sum, item) => sum + (item.taxAmount / 2));
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'billNumber': billNumber,
      'billDate': billDate,
      'supplierName': supplierName,
      'supplierAddress': supplierAddress,
      'supplierGstNumber': supplierGstNumber,
      'supplierPhone': supplierPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'cgst': cgst,
      'sgst': sgst,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PurchaseBill.fromMap(Map<String, dynamic> map) {
    return PurchaseBill(
      id: map['_id']?.toString(),
      billNumber: map['billNumber'] ?? '',
      billDate: map['billDate'] ?? '',
      supplierName: map['supplierName'] ?? '',
      supplierAddress: map['supplierAddress'] ?? '',
      supplierGstNumber: map['supplierGstNumber'] ?? '',
      supplierPhone: map['supplierPhone'] ?? '',
      items: (map['items'] as List?)
          ?.map((item) => PurchaseItem.fromMap(item))
          .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }
}