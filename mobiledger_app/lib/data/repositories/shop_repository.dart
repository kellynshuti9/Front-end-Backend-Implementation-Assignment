import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shop_model.dart';

class ShopRepository {
  final FirebaseFirestore _db;
  ShopRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('shops');

  Stream<List<ShopModel>> watchAllShops() =>
      _col.orderBy('productCount', descending: true).snapshots().map(
          (s) => s.docs.map((d) => ShopModel.fromMap(d.data(), d.id)).toList());

  Future<ShopModel?> getShop(String shopId) async {
    final doc = await _col.doc(shopId).get();
    if (!doc.exists) return null;
    return ShopModel.fromMap(doc.data()!, doc.id);
  }

  Future<ShopModel?> getShopByOwner(String ownerId) async {
    final snap = await _col.where('ownerId', isEqualTo: ownerId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return ShopModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  Future<void> updateShop(String shopId, Map<String, dynamic> data) =>
      _col.doc(shopId).update(data);

  /// Search shops by name, category, or products
  Future<List<ShopModel>> searchShops(String query) async {
    final lower = query.toLowerCase();
    final snap = await _col.get();
    return snap.docs
        .map((d) => ShopModel.fromMap(d.data(), d.id))
        .where((s) =>
            s.name.toLowerCase().contains(lower) ||
            s.category.toLowerCase().contains(lower) ||
            s.location.toLowerCase().contains(lower) ||
            s.topProducts.any((p) => p.toLowerCase().contains(lower)))
        .toList();
  }
}
