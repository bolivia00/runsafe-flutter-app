import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _consentKey = 'user_has_consented';
  static const String _photoPathKey = 'user_photo_path';
  static const String _photoUpdatedAtKey = 'user_photo_updated_at';

  // --- NOVA CHAVE PARA A LISTA DE METAS ---
  static const String _weeklyGoalsKey = 'weekly_goals_list';

  // --- Métodos de Consentimento ---
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

  // --- Métodos da Foto ---
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

  // --- NOVOS MÉTODOS PARA AS METAS ---

  /// Salva a lista de metas (em formato JSON String)
  Future<void> saveWeeklyGoalsJson(String goalsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_weeklyGoalsKey, goalsJson);
  }

  /// Lê a lista de metas (em formato JSON String)
  Future<String?> getWeeklyGoalsJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_weeklyGoalsKey);
  }
}