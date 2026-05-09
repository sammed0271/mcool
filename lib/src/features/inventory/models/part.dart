class Part {
  final int? id;
  final String partNumber;
  final String name;
  final String category;
  final String applianceType;
  final String? brand;
  final int quantity;
  final int minimumStock;
  final double purchasePrice;
  final double sellingPrice;
  final String? supplier;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Part({this.id, required this.partNumber, required this.name, required this.category, required this.applianceType, this.brand, required this.quantity, required this.minimumStock, required this.purchasePrice, required this.sellingPrice, this.supplier, this.location, required this.createdAt, required this.updatedAt});

  bool get isLowStock => quantity <= minimumStock;

  factory Part.fromMap(Map<String, dynamic> map) => Part(
        id: (map['id'] as num?)?.toInt(),
        partNumber: map['part_number'] as String,
        name: map['name'] as String,
        category: map['category'] as String,
        applianceType: map['appliance_type'] as String,
        brand: map['brand'] as String?,
        quantity: (map['quantity'] as num).toInt(),
        minimumStock: (map['minimum_stock'] as num).toInt(),
        purchasePrice: (map['purchase_price'] as num).toDouble(),
        sellingPrice: (map['selling_price'] as num).toDouble(),
        supplier: map['supplier'] as String?,
        location: map['location'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'part_number': partNumber,
        'name': name,
        'category': category,
        'appliance_type': applianceType,
        'brand': brand,
        'quantity': quantity,
        'minimum_stock': minimumStock,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'supplier': supplier,
        'location': location,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
