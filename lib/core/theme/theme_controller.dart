import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controlador de tema do aplicativo.
/// 
/// Gerencia o [ThemeMode] atual e notifica ouvintes quando ele muda.
/// Isso permite que o [MaterialApp] reconstrua com o novo tema.
class ThemeController extends ChangeNotifier {
  // Chave usada para armazenar o tema
  static const String _themeModeKey = 'theme_mode';
  
  ThemeMode _mode = ThemeMode.system;

  /// Retorna o modo de tema atual.
  ThemeMode get mode => _mode;

  /// Retorna true se o modo atual é escuro.
  bool get isDarkMode => _mode == ThemeMode.dark;

  /// Retorna true se o modo atual segue o sistema.
  bool get isSystemMode => _mode == ThemeMode.system;

  /// Carrega o tema salvo do SharedPreferences.
  /// 
  /// Deve ser chamado antes do runApp() no main.dart.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString(_themeModeKey) ?? 'system';
    _mode = _stringToThemeMode(savedMode);
    debugPrint('🎨 Tema carregado: $savedMode → $_mode');
  }

  /// Altera o modo de tema, salva e notifica os ouvintes.
  /// 
  /// Exemplo:
  /// ```dart
  /// controller.setMode(ThemeMode.dark);
  /// ```
  Future<void> setMode(ThemeMode newMode) async {
    if (_mode != newMode) {
      _mode = newMode;
      
      // Salvar no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(newMode));
      
      notifyListeners();
    }
  }

  /// Alterna entre claro e escuro.
  /// 
  /// Se estiver em modo sistema, detecta o tema atual e inverte.
  Future<void> toggle(Brightness currentBrightness) async {
    ThemeMode newMode;
    if (_mode == ThemeMode.system) {
      // Se estava em sistema, vai para o oposto do atual
      newMode = currentBrightness == Brightness.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    } else {
      // Alterna entre claro e escuro
      newMode = _mode == ThemeMode.dark 
          ? ThemeMode.light 
          : ThemeMode.dark;
    }
    await setMode(newMode);
  }

  /// Converte String para ThemeMode.
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Converte ThemeMode para String.
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
