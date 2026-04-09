import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const _kLang = 'language';
  static const _kCurr = 'currency';
  static const _kDark = 'darkMode';
  static const _kSync = 'autoSync';
  static const _kNotif = 'notifications';
  static const _kSaver = 'dataSaver';

  String _language = 'en';
  String _currency = 'RWF';
  bool _darkMode = false;
  bool _autoSync = true;
  bool _notifications = true;
  bool _dataSaver = false;
  bool _initialized = false;

  String get language => _language;
  String get currency => _currency;
  bool get darkMode => _darkMode;
  bool get autoSync => _autoSync;
  bool get notifications => _notifications;
  bool get dataSaver => _dataSaver;
  bool get initialized => _initialized;
  bool get isKinyarwanda => _language == 'rw';

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _language = prefs.getString(_kLang) ?? 'en';
    _currency = prefs.getString(_kCurr) ?? 'RWF';
    _darkMode = prefs.getBool(_kDark) ?? false;
    _autoSync = prefs.getBool(_kSync) ?? true;
    _notifications = prefs.getBool(_kNotif) ?? true;
    _dataSaver = prefs.getBool(_kSaver) ?? false;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String v) async {
    _language = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, v);
  }

  Future<void> setCurrency(String v) async {
    _currency = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurr, v);
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kDark, v);
  }

  Future<void> setAutoSync(bool v) async {
    _autoSync = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSync, v);
  }

  Future<void> setNotifications(bool v) async {
    _notifications = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kNotif, v);
  }

  Future<void> setDataSaver(bool v) async {
    _dataSaver = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSaver, v);
  }

  Future<void> clearCache() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    _language = 'en';
    _currency = 'RWF';
    _darkMode = false;
    _autoSync = true;
    _notifications = true;
    _dataSaver = false;
    notifyListeners();
  }
}
