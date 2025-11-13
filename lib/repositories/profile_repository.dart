import 'dart:io'; // <-- Faltava este (para 'File')
import 'package:flutter/material.dart'; // <-- Faltava este (para 'ChangeNotifier', 'debugPrint', etc.)
import 'package:image_picker/image_picker.dart'; // <-- Faltava este (para 'ImagePicker', 'XFile', 'ImageSource')
import 'package:runsafe/services/local_photo_store.dart';
import 'package:runsafe/services/storage_service.dart';

// Agora ele sabe o que é 'ChangeNotifier'
class ProfileRepository extends ChangeNotifier {
  
  final LocalPhotoStore _photoStore = LocalPhotoStore();
  final StorageService _storageService = StorageService();
  // E agora ele sabe o que é 'ImagePicker'
  final ImagePicker _picker = ImagePicker();

  String? _photoPath;
  String? get photoPath => _photoPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadPhotoPath() async {
    _photoPath = await _storageService.getPhotoPath();
    notifyListeners(); // Agora ele sabe o que é 'notifyListeners'
  }

  // Agora ele sabe o que é 'ImageSource'
  Future<void> updateProfilePicture(ImageSource source) async {
    _setLoading(true);
    try {
      // Agora ele sabe o que é 'XFile'
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        _setLoading(false);
        return; 
      }

      final String? oldPath = _photoPath;

      // Agora ele sabe o que é 'File'
      final newPath = await _photoStore.savePhoto(File(pickedFile.path));
      
      await _storageService.savePhotoPath(newPath);

      if (oldPath != null) {
        await _photoStore.deletePhoto(oldPath);
      }

      _photoPath = newPath;
      
    } catch (e) {
      debugPrint("Erro ao atualizar foto: $e"); // Agora ele sabe o que é 'debugPrint'
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeProfilePicture() async {
    _setLoading(true);
    try {
      if (_photoPath == null) return; 

      final String pathToRemove = _photoPath!;
      
      await _storageService.clearPhotoPath();
      
      await _photoStore.deletePhoto(pathToRemove);

      _photoPath = null;
      
    } catch (e) {
      debugPrint("Erro ao remover foto: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}