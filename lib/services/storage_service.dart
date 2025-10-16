import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _consentKey = 'user_has_consented';

  // Função para SALVAR que o usuário deu o consentimento.
  Future<void> saveUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
  }

  // Função para VERIFICAR se o usuário já deu o consentimento antes.
  Future<bool> hasUserConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  // NOVO MÉTODO: Função para REVOGAR (apagar) o consentimento do usuário.
  Future<void> revokeUserConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
  }
}