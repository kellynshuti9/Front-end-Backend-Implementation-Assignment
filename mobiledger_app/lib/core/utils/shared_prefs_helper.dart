import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> setLanguage(String language) async {
    await _prefs?.setString('language', language);
  }

  static String? getLanguage() {
    return _prefs?.getString('language');
  }

  static Future<void> setUserLoggedIn(bool isLoggedIn) async {
    await _prefs?.setBool('is_logged_in', isLoggedIn);
  }

  static bool isUserLoggedIn() {
    return _prefs?.getBool('is_logged_in') ?? false;
  }

  static Future<void> clear() async {
    await _prefs?.clear();
  }
}