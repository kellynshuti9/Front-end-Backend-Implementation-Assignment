class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String username;
  final String phoneNumber;
  final String location;
  final String? photoUrl;
  final String shopName;
  final List<String> followedShopIds;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.username = '',
    this.phoneNumber = '',
    this.location = '',
    this.photoUrl,
    this.shopName = '',
    this.followedShopIds = const [],
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) => UserModel(
        uid: uid,
        fullName: map['fullName'] as String? ?? '',
        email: map['email'] as String? ?? '',
        username: map['username'] as String? ?? '',
        phoneNumber: map['phoneNumber'] as String? ?? '',
        location: map['location'] as String? ?? '',
        photoUrl: map['photoUrl'] as String?,
        shopName: map['shopName'] as String? ?? '',
        followedShopIds:
            List<String>.from(map['followedShopIds'] as List? ?? []),
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
        'location': location,
        'photoUrl': photoUrl,
        'shopName': shopName,
        'followedShopIds': followedShopIds,
        'createdAt': createdAt.toIso8601String(),
      };

  UserModel copyWith({
    String? fullName,
    String? username,
    String? phoneNumber,
    String? location,
    String? photoUrl,
    String? shopName,
    List<String>? followedShopIds,
  }) =>
      UserModel(
        uid: uid,
        fullName: fullName ?? this.fullName,
        email: email,
        username: username ?? this.username,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        location: location ?? this.location,
        photoUrl: photoUrl ?? this.photoUrl,
        shopName: shopName ?? this.shopName,
        followedShopIds: followedShopIds ?? this.followedShopIds,
        createdAt: createdAt,
      );
}
