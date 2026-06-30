class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName'] as String? ?? (json['product'] != null ? json['product']['name'] as String? : null) ?? '',
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: json['unitPrice'] != null ? double.tryParse(json['unitPrice'].toString()) ?? 0.0 : 0.0,
      totalPrice: json['totalPrice'] != null ? double.tryParse(json['totalPrice'].toString()) ?? 0.0 : 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderId': orderId,
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
    'totalPrice': totalPrice,
  };
}

class Order {
  final String id;
  final String farmerId;
  final String? distributorId;
  final String orderNumber;
  final double subtotal;
  final double platformFee;
  final double taxAmount;
  final double totalAmount;
  final String paymentStatus; // pending, paid, failed, refunded
  final String orderStatus; // created, confirmed, dispatched, delivered, cancelled
  final List<OrderItem> items;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.farmerId,
    this.distributorId,
    required this.orderNumber,
    required this.subtotal,
    required this.platformFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    this.items = const [],
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];
    return Order(
      id: json['id']?.toString() ?? '',
      farmerId: json['farmerId']?.toString() ?? '',
      distributorId: json['distributorId']?.toString(),
      orderNumber: json['orderNumber'] as String? ?? '',
      subtotal: json['subtotal'] != null ? double.tryParse(json['subtotal'].toString()) ?? 0.0 : 0.0,
      platformFee: json['platformFee'] != null ? double.tryParse(json['platformFee'].toString()) ?? 0.0 : 0.0,
      taxAmount: json['taxAmount'] != null ? double.tryParse(json['taxAmount'].toString()) ?? 0.0 : 0.0,
      totalAmount: json['totalAmount'] != null ? double.tryParse(json['totalAmount'].toString()) ?? 0.0 : 0.0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      orderStatus: json['orderStatus'] as String? ?? 'created',
      items: list,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farmerId': farmerId,
    'distributorId': distributorId,
    'orderNumber': orderNumber,
    'subtotal': subtotal,
    'platformFee': platformFee,
    'taxAmount': taxAmount,
    'totalAmount': totalAmount,
    'paymentStatus': paymentStatus,
    'orderStatus': orderStatus,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };
}
