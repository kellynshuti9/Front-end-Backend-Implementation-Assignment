import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/order_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/other_repositories.dart';

// ─── OrderProvider ────────────────────────────────────────────────────────────

class OrderProvider with ChangeNotifier {
  final OrderRepository _repo;
  List<OrderModel> _orders = [];
  bool _loading = false;
  StreamSubscription<List<OrderModel>>? _sub;

  OrderProvider({required OrderRepository repository}) : _repo = repository;

  bool get loading => _loading;
  List<OrderModel> get orders => _orders;
  List<OrderModel> get active => _orders
      .where((o) =>
          o.status == OrderStatus.active || o.status == OrderStatus.processing)
      .toList();
  List<OrderModel> get completed =>
      _orders.where((o) => o.status == OrderStatus.delivered).toList();
  List<OrderModel> get cancelled =>
      _orders.where((o) => o.status == OrderStatus.cancelled).toList();

  double get totalSalesThisMonth {
    final now = DateTime.now();
    return _orders
        .where((o) =>
            o.status == OrderStatus.delivered &&
            o.createdAt.month == now.month &&
            o.createdAt.year == now.year)
        .fold(0.0, (s, o) => s + o.total);
  }

  void watchOrders(String buyerId) {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _repo.watchBuyerOrders(buyerId).listen(
      (list) {
        _orders = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  Future<String?> placeOrder(OrderModel order) async {
    try {
      return await _repo.placeOrder(order);
    } catch (_) {
      return null;
    }
  }

  Future<void> cancelOrder(String id) => _repo.cancelOrder(id);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─── CreditProvider ───────────────────────────────────────────────────────────

class CreditProvider with ChangeNotifier {
  final CreditRepository _repo;
  List<CreditModel> _credits = [];
  bool _loading = false;
  StreamSubscription<List<CreditModel>>? _sub;

  CreditProvider({required CreditRepository repository}) : _repo = repository;

  bool get loading => _loading;
  List<CreditModel> get credits => _credits;
  List<CreditModel> get overdue => _credits
      .where((c) => c.status == CreditStatus.overdue || c.isOverdue)
      .toList();
  List<CreditModel> get active => _credits
      .where((c) => c.status == CreditStatus.active && !c.isOverdue)
      .toList();
  List<CreditModel> get paid =>
      _credits.where((c) => c.status == CreditStatus.paid).toList();

  double get totalOwed => _credits
      .where((c) => c.status != CreditStatus.paid)
      .fold(0.0, (s, c) => s + c.remaining);
  double get totalOverdue => overdue.fold(0.0, (s, c) => s + c.remaining);

  void watchCredits(String uid) {
    _sub?.cancel();
    _loading = true;
    notifyListeners();
    _sub = _repo.watchCredits(uid).listen(
      (list) {
        _credits = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  Future<bool> addCredit(CreditModel c) async {
    try {
      await _repo.addCredit(c);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCredit(String id, Map<String, dynamic> data) async {
    try {
      await _repo.updateCredit(id, data);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCredit(String id) async {
    try {
      await _repo.deleteCredit(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
