import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// غلاف فوق Firebase Analytics مع سقوط آمن (graceful fallback): إن لم يكن
/// مشروع Firebase مُعدّاً بعد (google-services.json / firebase_options.dart)
/// فإن [init] تفشل بصمت والتطبيق يستمر بالعمل بشكل طبيعي بدون تحليلات،
/// بدل أن يتعطل عند الإقلاع.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  bool _ready = false;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      _ready = true;
    } catch (e) {
      debugPrint('Analytics معطّلة (لا يوجد إعداد Firebase حتى الآن): $e');
      _ready = false;
    }
  }

  Future<void> logScreenView(String screenName) async {
    if (!_ready || _analytics == null) return;
    try {
      await _analytics!.logScreenView(screenName: screenName);
    } catch (_) {
      // تجاهل أي خطأ شبكة/تحليلات حتى لا يؤثر على تجربة المستخدم
    }
  }

  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!_ready || _analytics == null) return;
    try {
      await _analytics!.logEvent(name: name, parameters: parameters);
    } catch (_) {}
  }
}
