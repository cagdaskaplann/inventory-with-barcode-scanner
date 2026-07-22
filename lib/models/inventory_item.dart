import 'dart:convert';

class InventoryItem {
  final String barcode;
  String name;
  int quantity;
  String? supplier;

  InventoryItem({
    required this.barcode,
    required this.name,
    this.quantity = 1,
    this.supplier,
  });

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'quantity': quantity,
      'supplier': supplier,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 0,
      supplier: map['supplier'],
    );
  }

  String toJson() => json.encode(toMap());

  factory InventoryItem.fromJson(String source) => InventoryItem.fromMap(json.decode(source));
}
