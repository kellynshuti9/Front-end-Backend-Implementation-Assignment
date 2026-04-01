// lib/data/models/product_model.dart
class ProductModel {
  final String? id;
  final String productName;
  final String category;
  final int price;
  final int stock;
  final String description;
  final bool isExpense;
  final String sellerId;
  final String sellerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String> images;

  ProductModel({
    this.id,
    required this.productName,
    required this.category,
    required this.price,
    required this.stock,
    required this.description,
    required this.isExpense,
    required this.sellerId,
    required this.sellerName,
    this.createdAt,
    this.updatedAt,
    this.images = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'category': category,
      'price': price,
      'stock': stock,
      'description': description,
      'isExpense': isExpense,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'images': images,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ProductModel(
      id: id ?? map['id'],
      productName: map['productName'] ?? '',
      category: map['category'] ?? '',
      price: map['price'] ?? 0,
      stock: map['stock'] ?? 0,
      description: map['description'] ?? '',
      isExpense: map['isExpense'] ?? false,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      images: List<String>.from(map['images'] ?? []),
    );
  }
}