import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _consentKey = 'user_has_consented';
  static const String _photoPathKey = 'user_photo_path';
  static const String _photoUpdatedAtKey = 'user_photo_updated_at';
  static const String _weeklyGoalsKey = 'weekly_goals_list';
  static const String _safetyAlertsKey = 'safety_alerts_list';
  static const String _waypointsKey = 'waypoints_list';
  static const String _runningRoutesKey = 'running_routes_list';

  // --- CONSENTIMENTO ---
  Future<void> saveUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
  }

  Future<bool> hasUserConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> revokeUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
  }

  // --- FOTO DE PERFIL ---
  Future<void> savePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoPathKey, path);
    await prefs.setString(_photoUpdatedAtKey, DateTime.now().toIso8601String());
  }

  Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoPathKey);
  }

  Future<void> clearPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPathKey);
    await prefs.remove(_photoUpdatedAtKey);
  }

  // --- METAS SEMANAIS ---
  Future<void> saveWeeklyGoalsJson(String goalsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyGoalsKey, goalsJson);
  }

  Future<String?> getWeeklyGoalsJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weeklyGoalsKey);
  }

  // --- OUTROS (Alertas, Waypoints, Rotas) ---
  Future<void> saveSafetyAlertsJson(String json) async => (await SharedPreferences.getInstance()).setString(_safetyAlertsKey, json);
  Future<String?> getSafetyAlertsJson() async => (await SharedPreferences.getInstance()).getString(_safetyAlertsKey);
  
  Future<void> saveWaypointsJson(String json) async => (await SharedPreferences.getInstance()).setString(_waypointsKey, json);
  Future<String?> getWaypointsJson() async => (await SharedPreferences.getInstance()).getString(_waypointsKey);
  
  Future<void> saveRunningRoutesJson(String json) async => (await SharedPreferences.getInstance()).setString(_runningRoutesKey, json);
  Future<String?> getRunningRoutesJson() async => (await SharedPreferences.getInstance()).getString(_runningRoutesKey);
}