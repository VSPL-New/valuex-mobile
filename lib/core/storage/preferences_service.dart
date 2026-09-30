import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService();
});

class PreferencesService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> setOnboardingComplete(bool value) async {
    final prefs = await _instance;
    return prefs.setBool(StorageKeys.onboardingComplete, value);
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await _instance;
    return prefs.getBool(StorageKeys.onboardingComplete) ?? false;
  }

  Future<bool> setString(String key, String value) async {
    final prefs = await _instance;
    return prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await _instance;
    return prefs.getString(key);
  }

  Future<bool> remove(String key) async {
    final prefs = await _instance;
    return prefs.remove(key);
  }

  Future<bool> clear() async {
    final prefs = await _instance;
    return prefs.clear();
  }
}
