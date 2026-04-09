import 'package:intl/intl.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        productId: m['productId'] as String? ?? '',
        productName: m['productName'] as String? ?? '',
        quantity: m['quantity'] as int? ?? 1,
        unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };
}

enum OrderStatus { active, processing, delivered, cancelled }

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String deliveryAddress;
  final String paymentMethod;
  final OrderStatus status;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.buyerId,
    this.sellerId = '',
    required this.items,
    required this.subtotal,
    this.deliveryFee = 500,
    this.discount = 0,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  double get total => subtotal + deliveryFee - discount;
  String get orderNumber => 'MOB-${id.substring(0, 12).toUpperCase()}';
  String get formattedDate => DateFormat('d MMM yyyy').format(createdAt);

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) => OrderModel(
        id: id,
        buyerId: map['buyerId'] as String? ?? '',
        sellerId: map['sellerId'] as String? ?? '',
        items: (map['items'] as List? ?? [])
            .map((e) => OrderItem.fromMap(e as Map<String, dynamic>))
            .toList(),
        subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 500,
        discount: (map['discount'] as num?)?.toDouble() ?? 0,
        deliveryAddress: map['deliveryAddress'] as String? ?? '',
        paymentMethod: map['paymentMethod'] as String? ?? '',
        status: OrderStatus.values.firstWhere(
          (e) => e.name == (map['status'] as String? ?? 'active'),
          orElse: () => OrderStatus.active,
        ),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'buyerId': buyerId,
        'sellerId': sellerId,
        'items': items.map((e) => e.toMap()).toList(),
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'discount': discount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
      };
}
