import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/repositories/profile_repository.dart';
import 'package:runsafe/utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // 1. MUDANÇA NA LÓGICA DO AVATAR
  Widget _buildUserAvatar(BuildContext context, ProfileRepository repository) {
    const double avatarRadius = 36.0;
    const String userInitials = "BT";

    // O CircleAvatar agora terá um fundo padrão...
    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: AppColors.navy,
      // ...e seu 'child' será ou a foto ou as iniciais.
      child: (repository.photoPath != null)
          // SE TIVER FOTO:
          ? ClipOval( // Usamos ClipOval para deixar a imagem redonda
              child: Image.file(
                File(repository.photoPath!),
                fit: BoxFit.cover, // Garante que a imagem preencha o círculo
                width: avatarRadius * 2,  // 72dp
                height: avatarRadius * 2, // 72dp
                
                // 2. ESPECIFICAÇÃO DE PERFORMANCE DO PRD 
                // Define o tamanho máximo da imagem em memória.
                cacheWidth: 256, 
                cacheHeight: 256,
              ),
            )
          // SE NÃO TIVER FOTO (FALLBACK):
          : const Text(
              userInitials,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }

  // (O restante do arquivo é igual ao que fizemos na Etapa 3)

  void _showPhotoOptions(BuildContext context, ProfileRepository repository) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tirar Foto (Câmera)'),
                onTap: () {
                  repository.updateProfilePicture(ImageSource.camera);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  repository.updateProfilePicture(ImageSource.gallery);
                  Navigator.of(ctx).pop();
                },
              ),
              if (repository.photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover Foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    repository.removeProfilePicture();
                    Navigator.of(ctx).pop();
                  },
                ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                child: Text(
                  'Sua foto fica salva apenas neste dispositivo. Você pode removê-la quando quiser.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const String userName = "Bolivar Torres Neto";

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<ProfileRepository>(
            builder: (context, repository, child) {
              return UserAccountsDrawerHeader(
                accountName: const Text(
                  userName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                accountEmail: const Text("Editar foto de perfil"),
                currentAccountPicture: Tooltip(
                  message: "Alterar foto de perfil",
                  child: GestureDetector(
                    onTap: () {
                      _showPhotoOptions(context, repository);
                    },
                    child: Semantics(
                      label: "Avatar do usuário. Toque para alterar a foto de perfil.",
                      button: true,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildUserAvatar(context, repository),
                          if (repository.isLoading)
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                  color: AppColors.emerald,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Início'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}