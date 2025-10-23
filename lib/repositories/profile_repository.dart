import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runsafe/services/local_photo_store.dart';
import 'package:runsafe/services/storage_service.dart';

// 1. Transformamos o Repositório em um "ChangeNotifier".
// Isso permite que ele avise a UI (o Drawer) quando a foto mudar.
class ProfileRepository extends ChangeNotifier {
  // 2. Instanciamos nossos serviços e o image_picker.
  final LocalPhotoStore _photoStore = LocalPhotoStore();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  // 3. Variáveis de estado que a UI vai ler.
  String? _photoPath;
  String? get photoPath => _photoPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Carrega o caminho da foto salva (do SharedPreferences)
  /// quando o app inicia.
  Future<void> loadPhotoPath() async {
    _photoPath = await _storageService.getPhotoPath();
    notifyListeners(); // Avisa a UI que o caminho foi carregado.
  }

  /// Pega uma nova foto (câmera ou galeria), salva, e atualiza o estado.
  Future<void> updateProfilePicture(ImageSource source) async {
    _setLoading(true);
    try {
      // 1. Usa o image_picker para pegar a imagem.
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        _setLoading(false);
        return; // Usuário cancelou
      }

      // 2. Guarda o caminho da foto antiga (se existir) para apagá-la depois.
      final String? oldPath = _photoPath;

      // 3. Salva a nova foto (comprimindo) no diretório do app.
      final newPath = await _photoStore.savePhoto(File(pickedFile.path));
      
      // 4. Salva o NOVO caminho no SharedPreferences.
      await _storageService.savePhotoPath(newPath);

      // 5. Apaga a foto ANTIGA do armazenamento.
      if (oldPath != null) {
        await _photoStore.deletePhoto(oldPath);
      }

      // 6. Atualiza o estado interno e avisa a UI.
      _photoPath = newPath;
      
    } catch (e) {
      debugPrint("Erro ao atualizar foto: $e");
      // (Opcional) Poderíamos adicionar uma variável de erro para mostrar na UI.
    } finally {
      _setLoading(false);
    }
  }

  /// Remove a foto de perfil atual.
  Future<void> removeProfilePicture() async {
    _setLoading(true);
    try {
      if (_photoPath == null) return; // Nenhuma foto para remover

      final String pathToRemove = _photoPath!;
      
      // 1. Limpa o caminho do SharedPreferences.
      await _storageService.clearPhotoPath();
      
      // 2. Apaga o arquivo físico.
      await _photoStore.deletePhoto(pathToRemove);

      // 3. Atualiza o estado interno e avisa a UI.
      _photoPath = null;
      
    } catch (e) {
      debugPrint("Erro ao remover foto: $e");
    } finally {
      _setLoading(false);
    }
  }

  // Função auxiliar para notificar a UI sobre o estado de carregamento.
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}