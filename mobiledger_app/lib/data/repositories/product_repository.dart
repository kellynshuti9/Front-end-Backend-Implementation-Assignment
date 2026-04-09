import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository {
  final FirebaseFirestore _db;
  ProductRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('products');

  // ─── CREATE ───────────────────────────────────────────────────────────────
  Future<String> addProduct(ProductModel p) async {
    final doc = await _col.add(p.toMap());
    // Update shop's productCount
    await _db.collection('shops').doc(p.ownerId).update({
      'productCount': FieldValue.increment(1),
    });
    return doc.id;
  }

  // ─── READ (own products) ──────────────────────────────────────────────────
  Stream<List<ProductModel>> watchOwnerProducts(String ownerId) => _col
      .where('ownerId', isEqualTo: ownerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());

  // ─── READ (all products – marketplace / browse) ───────────────────────────
  Stream<List<ProductModel>> watchAllProducts({String? category}) {
    Query<Map<String, dynamic>> q = _col;
    if (category != null && category.isNotEmpty && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    return q.orderBy('createdAt', descending: true).snapshots().map((s) =>
        s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());
  }

  // ─── READ (products of a specific shop) ───────────────────────────────────
  Stream<List<ProductModel>> watchShopProducts(String ownerId) => _col
      .where('ownerId', isEqualTo: ownerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());

  Future<ProductModel?> getProduct(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromMap(doc.data()!, id);
  }

  // ─── UPDATE ───────────────────────────────────────────────────────────────
  Future<void> updateProduct(String id, Map<String, dynamic> updates) async {
    updates['updatedAt'] = DateTime.now().toIso8601String();
    await _col.doc(id).update(updates);
  }

  // ─── DELETE ───────────────────────────────────────────────────────────────
  Future<void> deleteProduct(String id, String ownerId) async {
    await _col.doc(id).delete();
    await _db.collection('shops').doc(ownerId).update({
      'productCount': FieldValue.increment(-1),
    });
  }

  // ─── Search ───────────────────────────────────────────────────────────────
  Future<List<ProductModel>> searchProducts(String query) async {
    final lower = query.toLowerCase();
    // Firestore does not support full-text search; fetch recent and filter client-side
    final snap =
        await _col.orderBy('createdAt', descending: true).limit(200).get();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.data(), d.id))
        .where((p) =>
            p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower) ||
            p.shopName.toLowerCase().contains(lower))
        .toList();
  }
}
