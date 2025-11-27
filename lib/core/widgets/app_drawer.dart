import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/profile/data/repositories/profile_repository.dart';
import 'package:runsafe/core/utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Widget _buildUserAvatar(BuildContext context, ProfileRepository repository) {
    const double avatarRadius = 36.0;
    const String userInitials = "BT";

    return CircleAvatar(
      radius: avatarRadius,
      backgroundColor: AppColors.navy,
      child: (repository.photoPath != null)
          ? ClipOval(
              child: Image.file(
                File(repository.photoPath!),
                fit: BoxFit.cover,
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                cacheWidth: 256,
                cacheHeight: 256,
              ),
            )
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
                // --- AQUI ESTÁ A MUDANÇA ---
                // Envolvemos o texto em um GestureDetector
                accountEmail: GestureDetector(
                  onTap: () {
                    // Ao clicar no texto, abre o menu também
                    _showPhotoOptions(context, repository);
                  },
                  child: const Text(
                    "Editar foto de perfil",
                    style: TextStyle(decoration: TextDecoration.underline), // Bônus: Sublinhado para parecer link
                  ),
                ),
                // ---------------------------
                
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
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Minhas Metas'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/weekly-goals');
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: const Text('Alertas de Segurança'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/safety-alerts');
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_pin),
            title: const Text('Pontos de Rota'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/waypoints');
            },
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Minhas Rotas'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/running-routes');
            },
          ),
        ],
      ),
    );
  }
}
