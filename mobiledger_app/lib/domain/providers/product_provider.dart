import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _repo;

  List<ProductModel> _myProducts = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _shopProducts = [];
  bool _loadingMine = false;
  bool _loadingAll = false;
  String _searchQuery = '';
  String _filterCategory = '';
  String? _error;

  StreamSubscription<List<ProductModel>>? _mineSub;
  StreamSubscription<List<ProductModel>>? _allSub;
  StreamSubscription<List<ProductModel>>? _shopSub;

  ProductProvider({required ProductRepository repository}) : _repo = repository;

  // ── Getters ─────────────────────────────────────────────────────────────
  bool get loadingMine => _loadingMine;
  bool get loadingAll => _loadingAll;
  String? get error => _error;

  List<ProductModel> get myProducts {
    var list = List<ProductModel>.from(_myProducts);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  List<ProductModel> get allProducts {
    var list = List<ProductModel>.from(_allProducts);
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q) ||
              p.shopName.toLowerCase().contains(q))
          .toList();
    }
    if (_filterCategory.isNotEmpty && _filterCategory != 'All') {
      list = list.where((p) => p.category == _filterCategory).toList();
    }
    return list;
  }

  List<ProductModel> get shopProducts => _shopProducts;

  int get activeCount => _myProducts.where((p) => p.stockQuantity > 4).length;
  int get lowStockCount => _myProducts
      .where((p) => p.stockQuantity > 0 && p.stockQuantity < 5)
      .length;
  int get outCount => _myProducts.where((p) => p.stockQuantity == 0).length;

  // ── Start watching own products ──────────────────────────────────────────
  void watchMyProducts(String ownerId) {
    _mineSub?.cancel();
    _loadingMine = true;
    _error = null;
    notifyListeners();

    _mineSub = _repo.watchOwnerProducts(ownerId).listen(
      (list) {
        _myProducts = list;
        _loadingMine = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Failed to load products: $e';
        _loadingMine = false;
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  // ── Start watching all products (marketplace) ────────────────────────────
  void watchAllProducts() {
    _allSub?.cancel();
    _loadingAll = true;
    notifyListeners();

    _allSub = _repo.watchAllProducts().listen(
      (list) {
        _allProducts = list;
        _loadingAll = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _loadingAll = false;
        _error = 'Failed to load marketplace: $e';
        notifyListeners();
      },
      cancelOnError: false,
    );
  }

  // ── Watch products of a specific shop ────────────────────────────────────
  void watchShopProducts(String ownerId) {
    _shopSub?.cancel();
    _shopSub = _repo.watchShopProducts(ownerId).listen((list) {
      _shopProducts = list;
      notifyListeners();
    });
  }

  void stopWatchingShop() {
    _shopSub?.cancel();
    _shopProducts = [];
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────
  Future<bool> addProduct(ProductModel p) async {
    try {
      await _repo.addProduct(p);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(String id, Map<String, dynamic> updates) async {
    try {
      await _repo.updateProduct(id, updates);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id, String ownerId) async {
    try {
      await _repo.deleteProduct(id, ownerId);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── Search / Filter ───────────────────────────────────────────────────────
  void setSearch(String q) {
    _searchQuery = q;
    notifyListeners();
  }

  void setCategory(String cat) {
    _filterCategory = cat;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filterCategory = '';
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _mineSub?.cancel();
    _allSub?.cancel();
    _shopSub?.cancel();
    super.dispose();
  }
}
