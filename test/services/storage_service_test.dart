import 'package:flutter_test/flutter_test.dart';
import 'package:runsafe/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Grupo de testes para o StorageService
  group('StorageService Photo Tests', () {
    
    // Testa se o serviço consegue salvar um caminho de foto.
    test('should save photo path to SharedPreferences', () async {
      // 1. PREPARAÇÃO (Arrange)
      // Como não podemos usar o SharedPreferences real em um teste de unidade,
      // nós criamos um "dublê" (mock) com valores iniciais em memória.
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      const testPath = 'meu/teste/foto.jpg';

      // 2. AÇÃO (Act)
      // Chamamos o método que queremos testar.
      await storageService.savePhotoPath(testPath);

      // 3. VERIFICAÇÃO (Assert)
      // Verificamos se o "dublê" agora contém o valor que esperamos.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_photo_path'), testPath);
      expect(prefs.getString('user_photo_updated_at'), isNotNull);
    });

    // Testa se o serviço consegue ler o caminho da foto.
    test('should get photo path from SharedPreferences', () async {
      // 1. PREPARAÇÃO
      const testPath = 'meu/teste/foto.jpg';
      SharedPreferences.setMockInitialValues({
        'user_photo_path': testPath,
      });
      final storageService = StorageService();

      // 2. AÇÃO
      final path = await storageService.getPhotoPath();

      // 3. VERIFICAÇÃO
      expect(path, testPath);
    });

    // Testa se o serviço consegue apagar o caminho da foto.
    test('should clear photo path from SharedPreferences', () async {
      // 1. PREPARAÇÃO
      SharedPreferences.setMockInitialValues({
        'user_photo_path': 'caminho/para/apagar.jpg',
        'user_photo_updated_at': 'data-qualquer',
      });
      final storageService = StorageService();

      // 2. AÇÃO
      await storageService.clearPhotoPath();

      // 3. VERIFICAÇÃO
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_photo_path'), null);
      expect(prefs.getString('user_photo_updated_at'), null);
    });
  });
}