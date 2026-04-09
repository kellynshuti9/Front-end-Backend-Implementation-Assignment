const List<String> kCategories = [
  'Food & Groceries',
  'Vegetables',
  'Fruits',
  'Electronics',
  'Clothing',
  'Construction',
  'Health & Beauty',
  'Agriculture',
  'Furniture',
  'Other',
];

class ProductModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String shopName;
  final String name;
  final String category;
  final double price;
  final int stockQuantity;
  final String description;
  final List<String> imageUrls;
  final bool isExpense;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.ownerId,
    this.ownerName = '',
    this.shopName = '',
    required this.name,
    required this.category,
    required this.price,
    required this.stockQuantity,
    this.description = '',
    this.imageUrls = const [],
    this.isExpense = false,
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedPrice => '${price.toStringAsFixed(0)} RWF';

  String get stockStatus {
    if (stockQuantity == 0) return 'Out of Stock';
    if (stockQuantity < 5) return 'Low Stock';
    return 'Active';
  }

  bool get inStock => stockQuantity > 0;

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) =>
      ProductModel(
        id: id,
        ownerId: map['ownerId'] as String? ?? '',
        ownerName: map['ownerName'] as String? ?? '',
        shopName: map['shopName'] as String? ?? '',
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? '',
        price: (map['price'] as num?)?.toDouble() ?? 0,
        stockQuantity: map['stockQuantity'] as int? ?? 0,
        description: map['description'] as String? ?? '',
        imageUrls: List<String>.from(map['imageUrls'] as List? ?? []),
        isExpense: map['isExpense'] as bool? ?? false,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'ownerName': ownerName,
        'shopName': shopName,
        'name': name,
        'category': category,
        'price': price,
        'stockQuantity': stockQuantity,
        'description': description,
        'imageUrls': imageUrls,
        'isExpense': isExpense,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  ProductModel copyWith({
    String? name,
    String? category,
    double? price,
    int? stockQuantity,
    String? description,
    List<String>? imageUrls,
    bool? isExpense,
  }) =>
      ProductModel(
        id: id,
        ownerId: ownerId,
        ownerName: ownerName,
        shopName: shopName,
        name: name ?? this.name,
        category: category ?? this.category,
        price: price ?? this.price,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        description: description ?? this.description,
        imageUrls: imageUrls ?? this.imageUrls,
        isExpense: isExpense ?? this.isExpense,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}
