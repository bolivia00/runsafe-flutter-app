import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/repositories/profile_repository.dart';
import 'package:runsafe/widgets/app_drawer.dart';
import 'package:image_picker/image_picker.dart'; // <-- 1. IMPORTAÇÃO ADICIONADA

// 2. Criamos um "dublê" (Mock) do nosso ProfileRepository
class MockProfileRepository extends ChangeNotifier implements ProfileRepository {
  String? _photoPath;
  // 3. Corrigimos o aviso do lint tornando _isLoading 'final'
  final bool _isLoading = false; 

  @override
  String? get photoPath => _photoPath;
  @override
  bool get isLoading => _isLoading;

  void setPhotoPath(String? path) {
    _photoPath = path;
    notifyListeners();
  }

  // Agora o arquivo sabe o que é 'ImageSource'
  @override
  Future<void> loadPhotoPath() async {}
  @override
  Future<void> removeProfilePicture() async {}
  @override
  Future<void> updateProfilePicture(ImageSource source) async {}
}

void main() {
  // Função auxiliar para "construir" nosso widget para o teste
  Widget createWidgetUnderTest(ProfileRepository repository) {
    return ChangeNotifierProvider<ProfileRepository>.value(
      value: repository,
      child: const MaterialApp(
        home: Scaffold(
          drawer: AppDrawer(),
        ),
      ),
    );
  }

  group('AppDrawer Widget Tests', () {

    testWidgets('should display user initials ("BT") when there is no photo', (tester) async {
      // 1. PREPARAÇÃO
      final mockRepo = MockProfileRepository();
      mockRepo.setPhotoPath(null); // Garantimos que não há foto

      // 2. AÇÃO
      await tester.pumpWidget(createWidgetUnderTest(mockRepo));
      
      // Abre o Drawer para que ele seja construído
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pump(); // Espera a animação do drawer

      // 3. VERIFICAÇÃO
      expect(find.text('BT'), findsOneWidget);
    });

    testWidgets('should NOT display user initials when there is a photo', (tester) async {
      // 1. PREPARAÇÃO
      final mockRepo = MockProfileRepository();
      // Simulamos que temos um caminho de foto (não importa qual é o caminho, 
      // apenas que não é nulo)
      mockRepo.setPhotoPath('dummy/path/to/photo.jpg');

      // 2. AÇÃO
      await tester.pumpWidget(createWidgetUnderTest(mockRepo));
      
      final ScaffoldState state = tester.firstState(find.byType(Scaffold));
      state.openDrawer();
      await tester.pump();

      // 3. VERIFICAÇÃO
      // Verificamos que o fallback "BT" NÃO está mais na tela,
      // o que prova que o app tentou carregar a foto (FileImage).
      expect(find.text('BT'), findsNothing);
    });
  });
}