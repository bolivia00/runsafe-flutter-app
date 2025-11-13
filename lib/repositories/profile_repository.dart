import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runsafe/services/local_photo_store.dart';
import 'package:runsafe/services/storage_service.dart';

class ProfileRepository extends ChangeNotifier {
  
  final LocalPhotoStore _photoStore = LocalPhotoStore();
  final StorageService _storageService = StorageService();
  // CORRIGIDO: ImageKPicker -> ImagePicker
  final ImagePicker _picker = ImagePicker();

  String? _photoPath;
  String? get photoPath => _photoPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadPhotoPath() async {
    _photoPath = await _storageService.getPhotoPath();
    notifyListeners();
  }

  Future<void> updateProfilePicture(ImageSource source) async {
    _setLoading(true);
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) {
        _setLoading(false);
        return; 
      }

      final String? oldPath = _photoPath;
      final newPath = await _photoStore.savePhoto(File(pickedFile.path));
      await _storageService.savePhotoPath(newPath);

      if (oldPath != null) {
        await _photoStore.deletePhoto(oldPath);
      }
      _photoPath = newPath;
      
    } catch (e) {
      debugPrint("Erro ao atualizar foto: $e");
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