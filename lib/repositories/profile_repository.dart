import 'package:runsafe/services/local_photo_store.dart';
import 'package:runsafe/services/storage_service.dart';
class ProfileRepository extends ChangeNotifier {
  // As instâncias agora devem ser criadas sem ambiguidade
  final LocalPhotoStore _photoStore = LocalPhotoStore();
  final StorageService _storageService = StorageService();
  final ImagePicker _picker = ImagePicker();

  String? _photoPath;
  String? get photoPath => _photoPath;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadPhotoPath() async {
    // A chamada agora deve funcionar
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
      // Chamada ao LocalPhotoStore
      final newPath = await _photoStore.savePhoto(File(pickedFile.path));
      // Chamada ao StorageService (sem ambiguidade)
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
      // Chamada ao StorageService (sem ambiguidade)
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