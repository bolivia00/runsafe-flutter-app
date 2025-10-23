import 'package:flutter_test/flutter_test.dart';
import 'package:runsafe/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StorageService Photo Tests', () {
    
    test('should save photo path and updated_at timestamp to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final storageService = StorageService();
      const testPath = 'meu/teste/foto.jpg';

      await storageService.savePhotoPath(testPath);

      final prefs = await SharedPreferences.getInstance();
      // VERIFICAÇÃO ATUALIZADA:
      expect(prefs.getString('user_photo_path'), testPath);
      expect(prefs.getString('user_photo_updated_at'), isNotNull); // Verifica se a data foi salva
    });

    test('should get photo path from SharedPreferences', () async {
      const testPath = 'meu/teste/foto.jpg';
      SharedPreferences.setMockInitialValues({
        'user_photo_path': testPath,
      });
      final storageService = StorageService();

      final path = await storageService.getPhotoPath();

      expect(path, testPath);
    });

    test('should clear photo path and updated_at timestamp from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'user_photo_path': 'caminho/para/apagar.jpg',
        'user_photo_updated_at': 'data-qualquer',
      });
      final storageService = StorageService();

      await storageService.clearPhotoPath();

      final prefs = await SharedPreferences.getInstance();
      // VERIFICAÇÃO ATUALIZADA:
      expect(prefs.getString('user_photo_path'), null);
      expect(prefs.getString('user_photo_updated_at'), null); // Verifica se a data foi limpa
    });
  });
}