import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Chave para o consentimento (que já fizemos)
  static const String _consentKey = 'user_has_consented';

  // --- NOVAS CHAVES PARA A FOTO ---
  static const String _photoPathKey = 'user_photo_path';
  static const String _photoUpdatedAtKey = 'user_photo_updated_at';

  // --- MÉTODOS DE CONSENTIMENTO (JÁ EXISTENTES) ---

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

  // --- NOVOS MÉTODOS PARA A FOTO ---

  /// Salva o caminho (path) do arquivo da foto no SharedPreferences
  Future<void> savePhotoPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_photoPathKey, path);
    await prefs.setString(_photoUpdatedAtKey, DateTime.now().toIso8601String());
  }

  /// Pega o caminho (path) do arquivo da foto salvo
  Future<String?> getPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoPathKey);
  }

  /// Limpa o caminho (path) do arquivo da foto
  Future<void> clearPhotoPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_photoPathKey);
    await prefs.remove(_photoUpdatedAtKey);
  }
}