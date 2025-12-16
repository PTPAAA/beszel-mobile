import 'dart:convert';
import 'package:beszel_pro/models/alert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AlertManager {
  static final AlertManager _instance = AlertManager._internal();

  factory AlertManager() {
    return _instance;
  }

  AlertManager._internal();

  List<Alert> _alerts = [];
  
  List<Alert> get alerts => List.unmodifiable(_alerts);

  Future<void> loadAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? alertsJson = prefs.getStringList('local_alerts');

    if (alertsJson != null) {
      // Decode with error handling and limit
      final List<Alert> loaded = [];
      // Assuming list is stored as [newest, ..., oldest]
      for (final str in alertsJson) {
        if (loaded.length >= 50) break; 
        try {
          loaded.add(Alert.fromJson(jsonDecode(str)));
        } catch (_) {}
      }
      // Sort just in case, though insertion order should be preserved
      loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _alerts = loaded; 
    }
  }

  Future<void> addAlert(String title, String message, String type, String systemName) async {
    final alert = Alert(
      id: const Uuid().v4(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      systemName: systemName,
    );

    _alerts.insert(0, alert);
    if (_alerts.length > 50) {
      _alerts = _alerts.sublist(0, 50);
    }
    await _saveAlerts();
  }

  Future<void> _saveAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> alertsJson = _alerts
        .map((alert) => jsonEncode(alert.toJson()))
        .toList();
    await prefs.setStringList('local_alerts', alertsJson);
  }

  Future<void> clearAlerts() async {
    _alerts.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('local_alerts');
  }
}
