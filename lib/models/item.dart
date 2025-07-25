class Item {
  String description;
  double length;
  double breadth;
  int hsnCode;
  int quantity;
  double rate;
  double taxRate;

  Item({
    required this.description,
    required this.length,
    required this.breadth,
    required this.hsnCode,
    required this.quantity,
    required this.rate,
    required this.taxRate,
  });

  String get sizeString => (length==0 || breadth==0)?'':'$length x $breadth';

  double get size => length * breadth;

  double get totalSqft => size * quantity;

  double get amount => rate * totalSqft;

  double get taxAmount => amount * taxRate / 100;

  double get totalAmount => amount + taxAmount;
}
