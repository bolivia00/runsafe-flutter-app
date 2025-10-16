import 'package:shared_preferences/shared_preferences.dart';

// Este é nosso "Cozinheiro" que sabe como falar com o "Estoque" (SharedPreferences).
// A UI nunca falará com o SharedPreferences diretamente.

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
    // Retorna "true" se o consentimento foi salvo, ou "false" se não foi encontrado.
    return prefs.getBool(_consentKey) ?? false;
  }
}