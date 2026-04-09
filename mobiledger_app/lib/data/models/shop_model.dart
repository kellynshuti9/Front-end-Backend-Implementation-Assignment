class ShopModel {
  final String id;
  final String ownerId;
  final String name;
  final String location;
  final String about;
  final double rating;
  final int reviewCount;
  final int productCount;
  final String? imageUrl;
  final String phone;
  final List<String> topProducts;
  final String category;
  final int followerCount;
  final DateTime createdAt;

  const ShopModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.location = '',
    this.about = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.productCount = 0,
    this.imageUrl,
    this.phone = '',
    this.topProducts = const [],
    this.category = 'General',
    this.followerCount = 0,
    required this.createdAt,
  });

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) => ShopModel(
        id: id,
        ownerId: map['ownerId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        location: map['location'] as String? ?? '',
        about: map['about'] as String? ?? '',
        rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: map['reviewCount'] as int? ?? 0,
        productCount: map['productCount'] as int? ?? 0,
        imageUrl: map['imageUrl'] as String?,
        phone: map['phone'] as String? ?? '',
        topProducts: List<String>.from(map['topProducts'] as List? ?? []),
        category: map['category'] as String? ?? 'General',
        followerCount: map['followerCount'] as int? ?? 0,
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'location': location,
        'about': about,
        'rating': rating,
        'reviewCount': reviewCount,
        'productCount': productCount,
        'imageUrl': imageUrl,
        'phone': phone,
        'topProducts': topProducts,
        'category': category,
        'followerCount': followerCount,
        'createdAt': createdAt.toIso8601String(),
      };

  ShopModel copyWith({
    String? name,
    String? location,
    String? about,
    int? productCount,
    int? followerCount,
  }) =>
      ShopModel(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        location: location ?? this.location,
        about: about ?? this.about,
        rating: rating,
        reviewCount: reviewCount,
        productCount: productCount ?? this.productCount,
        imageUrl: imageUrl,
        phone: phone,
        topProducts: topProducts,
        category: category,
        followerCount: followerCount ?? this.followerCount,
        createdAt: createdAt,
      );
}
