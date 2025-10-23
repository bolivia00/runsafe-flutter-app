import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/repositories/profile_repository.dart';
import 'package:runsafe/utils/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  // 1. Criamos o widget "Avatar do Usuário"
  Widget _buildUserAvatar(BuildContext context, ProfileRepository repository) {
    const double avatarRadius = 36.0; // Tamanho do círculo (72dp no total)
    ImageProvider? backgroundImage;

    // Se tivermos um caminho de foto, usamos Image.file()
    if (repository.photoPath != null) {
      backgroundImage = FileImage(
        File(repository.photoPath!),
        // Otimização de performance: define o tamanho máximo da imagem em memória
        scale: 1.0, 
      );
    }

    return CircleAvatar(
      radius: avatarRadius, // Garante 72dp (maior que 48dp)
      backgroundColor: AppColors.navy,
      backgroundImage: backgroundImage, // Mostra a foto (se houver)
      // Se não houver foto (backgroundImage == null), mostra o fallback
      child: (backgroundImage == null)
          ? const Text(
              "BT",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null, // Se tem foto, não mostra o texto
    );
  }

  // 2. Criamos a função que mostra o "BottomSheet" (menu de opções)
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
                  // Chama o repositório para usar a câmera
                  repository.updateProfilePicture(ImageSource.camera);
                  Navigator.of(ctx).pop(); // Fecha o menu
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  // Chama o repositório para usar a galeria
                  repository.updateProfilePicture(ImageSource.gallery);
                  Navigator.of(ctx).pop();
                },
              ),
              // Só mostra "Remover Foto" se o usuário TIVER uma foto
              if (repository.photoPath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remover Foto', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    // Chama o repositório para remover a foto
                    repository.removeProfilePicture();
                    Navigator.of(ctx).pop();
                  },
                ),
              const Divider(),
              // 3. Mensagem de privacidade (requisito da LGPD)
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
          // 4. Usamos um "Consumer" para que este widget "ouça" as
          //    mudanças do ProfileRepository.
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
                  message: "Alterar foto de perfil", // Acessibilidade (A11Y)
                  child: GestureDetector(
                    onTap: () {
                      // 5. Permite que o usuário clique no avatar
                      //    e abre o menu de opções.
                      _showPhotoOptions(context, repository);
                    },
                    // 6. Adiciona Semantics para leitores de tela (A11Y)
                    child: Semantics(
                      label: "Avatar do usuário. Toque para alterar a foto de perfil.",
                      button: true,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildUserAvatar(context, repository),
                          // 7. Mostra um "loading" se estiver processando a imagem
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