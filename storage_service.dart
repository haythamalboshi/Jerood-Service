import 'package:shared_preferences/shared_preferences.dart';

/// غلاف خفيف فوق [SharedPreferences] لكل ما يحتاج التطبيق تذكّره محلياً:
/// الحي المختار، تفضيل الوضع الليلي، ونسخة احتياطية (cache) بسيطة من آخر
/// بيانات تم جلبها من كل تبويب في Google Sheets، لتبقى الشاشات تعمل حتى
/// بدون إنترنت.
class StorageService {
  static const _kNeighborhood = 'selected_neighborhood';
  static const _kDarkMode = 'dark_mode';
  static const _kCachePrefix = 'cache_';

  final SharedPreferences _prefs;

  StorageService._(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  // --- الحي المختار ---
  String? get selectedNeighborhood => _prefs.getString(_kNeighborhood);

  Future<void> setSelectedNeighborhood(String neighborhood) =>
      _prefs.setString(_kNeighborhood, neighborhood);

  // --- تفضيل المظهر (فاتح/داكن) ---
  bool get isDarkMode => _prefs.getBool(_kDarkMode) ?? false;

  Future<void> setDarkMode(bool value) => _prefs.setBool(_kDarkMode, value);

  // --- تخزين مؤقت لصفوف كل تبويب في الشيت، للعمل دون اتصال ---
  Future<void> cacheRows(String sheetName, List<List<dynamic>> rows) async {
    final encoded = rows
        .map((row) => row.map((cell) => cell.toString()).join('\t'))
        .join('\n');
    await _prefs.setString('$_kCachePrefix$sheetName', encoded);
  }

  List<List<dynamic>> readCachedRows(String sheetName) {
    final raw = _prefs.getString('$_kCachePrefix$sheetName');
    if (raw == null || raw.isEmpty) return [];
    return raw.split('\n').map((line) => line.split('\t')).toList();
  }
}
