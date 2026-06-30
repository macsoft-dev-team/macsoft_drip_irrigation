class Product {
  final String id;
  final String name;
  final String sku;
  final String type; // masterController, valve, accessory, serviceFee
  final String? description;
  final double price;
  final String status; // active, inactive

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.type,
    this.description,
    required this.price,
    required this.status,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      type: json['type'] as String? ?? 'accessory',
      description: json['description'] as String?,
      price: json['price'] != null ? double.tryParse(json['price'].toString()) ?? 0.0 : 0.0,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'type': type,
    'description': description,
    'price': price,
    'status': status,
  };
}
