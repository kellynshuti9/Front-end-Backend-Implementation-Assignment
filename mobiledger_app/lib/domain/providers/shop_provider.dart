import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/shop_model.dart';
import '../../data/repositories/shop_repository.dart';

class ShopProvider with ChangeNotifier {
  final ShopRepository _repo;

  List<ShopModel> _shops = [];
  List<ShopModel> _searchResult = [];
  bool _loading = false;
  String _query = '';
  String _tab = 'All'; // All | Nearby | Popular | Recommended
  StreamSubscription<List<ShopModel>>? _sub;

  ShopProvider({required ShopRepository repository}) : _repo = repository;

  bool get loading => _loading;
  String get query => _query;
  String get tab => _tab;

  List<ShopModel> get shops {
    List<ShopModel> list = _query.isNotEmpty ? _searchResult : _shops;
    switch (_tab) {
      case 'Popular':
        list = List.from(list)
          ..sort((a, b) => b.followerCount.compareTo(a.followerCount));
      case 'Recommended':
        list = List.from(list)..sort((a, b) => b.rating.compareTo(a.rating));
      default:
        break;
    }
    return list;
  }

  void watchShops() {
    _sub?.cancel();
    _loading = true;
    notifyListeners();

    _sub = _repo.watchAllShops().listen(
      (list) {
        _shops = list;
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

  Future<void> search(String q) async {
    _query = q;
    notifyListeners();
    if (q.isEmpty) return;
    _searchResult = await _repo.searchShops(q);
    notifyListeners();
  }

  void clearSearch() {
    _query = '';
    _searchResult = [];
    notifyListeners();
  }

  void setTab(String t) {
    _tab = t;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
