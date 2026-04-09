import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/credit_model.dart';

// ─── OrderRepository ──────────────────────────────────────────────────────────

class OrderRepository {
  final FirebaseFirestore _db;
  OrderRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('orders');

  Future<String> placeOrder(OrderModel order) async {
    final doc = await _col.add(order.toMap());
    return doc.id;
  }

  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) => _col
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => OrderModel.fromMap(d.data(), d.id)).toList());

  Future<void> updateStatus(String id, OrderStatus status) =>
      _col.doc(id).update({'status': status.name});

  Future<void> cancelOrder(String id) =>
      _col.doc(id).update({'status': OrderStatus.cancelled.name});
}

// ─── CreditRepository ─────────────────────────────────────────────────────────

class CreditRepository {
  final FirebaseFirestore _db;
  CreditRepository({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('credits');

  Future<String> addCredit(CreditModel c) async {
    final doc = await _col.add(c.toMap());
    return doc.id;
  }

  Stream<List<CreditModel>> watchCredits(String creditorId) => _col
      .where('creditorId', isEqualTo: creditorId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) =>
          s.docs.map((d) => CreditModel.fromMap(d.data(), d.id)).toList());

  Future<void> updateCredit(String id, Map<String, dynamic> updates) =>
      _col.doc(id).update(updates);

  Future<void> deleteCredit(String id) => _col.doc(id).delete();

  Future<void> markPaid(String id) => _col.doc(id).update({
        'amountPaid': _db
            .collection('credits')
            .doc(id)
            .get()
            .then((d) => d.data()?['amount'] ?? 0),
        'status': CreditStatus.paid.name,
      });
}
