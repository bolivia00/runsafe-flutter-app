import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 1. Importamos o Provider
import 'package:runsafe/repositories/profile_repository.dart'; // 2. Importamos nosso Repositório
import 'package:runsafe/screens/home_screen.dart';
import 'package:runsafe/screens/onboarding_screen.dart';
import 'package:runsafe/screens/privacy_policy_screen.dart';
import 'package:runsafe/screens/splash_screen.dart';
import 'package:runsafe/utils/app_colors.dart';

void main() {
  // 3. Modificamos o main para usar o Provider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ProfileRepository()..loadPhotoPath(),
      // 4. Criamos uma instância do ProfileRepository
      //    e já chamamos o método .loadPhotoPath() 
      //    para ele carregar a foto salva assim que o app iniciar.
      child: const RunSafeApp(),
    ),
  );
}

class RunSafeApp extends StatelessWidget {
  const RunSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunSafe',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.emerald,
          primary: AppColors.emerald,
          onPrimary: Colors.white,
          secondary: AppColors.navy,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: AppColors.gray,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/':(context) => const SplashScreen(), 
        '/onboarding': (context) => const OnboardingScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}