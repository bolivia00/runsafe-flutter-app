import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/core/utils/app_colors.dart'; // <--- Importante ter esse import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkConsentAndNavigate();
  }

  Future<void> _checkConsentAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    final bool hasConsented = await _storageService.hasUserConsented();
    
    // Rota correta conforme seu main.dart
    final String route = hasConsented ? '/home' : '/privacy';

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AQUI ESTAVA O PROBLEMA: Agora usa a cor oficial do App
      backgroundColor: AppColors.emerald, 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/runsafe_icon.svg',
              height: 120,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(height: 24),
            const Text(
              'RunSafe',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          ],
        ),
      ),
    );
  }
}