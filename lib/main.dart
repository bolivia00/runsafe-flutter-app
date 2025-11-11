import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
// 1. Caminho do Repositório corrigido para "domain/repositories"
import 'package:runsafe/domain/repositories/weekly_goal_repository.dart';
import 'package:runsafe/repositories/profile_repository.dart'; 
import 'package:runsafe/screens/home_screen.dart';
import 'package:runsafe/screens/onboarding_screen.dart';
import 'package:runsafe/screens/privacy_policy_screen.dart';
import 'package:runsafe/screens/splash_screen.dart';
import 'package:runsafe/screens/weekly_goal_list_page.dart';
import 'package:runsafe/utils/app_colors.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ProfileRepository()..loadPhotoPath(),
        ),
        ChangeNotifierProvider(
          create: (context) => WeeklyGoalRepository()..loadGoals(),
        ),
      ],
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
         // MANTENHA O SEU TEMA COMPLETO AQUI
         // (Vou resumir para não sobrecarregar)
         useMaterial3: true,
         colorScheme: ColorScheme.fromSeed(seedColor: AppColors.emerald),
         appBarTheme: const AppBarTheme(
           backgroundColor: AppColors.emerald,
           foregroundColor: Colors.white,
         ),
         // ... etc ...
      ),
      initialRoute: '/',
      routes: {
        '/':(context) => const SplashScreen(), 
        '/onboarding': (context) => const OnboardingScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/home': (context) => const HomeScreen(),
        '/weekly-goals': (context) => const WeeklyGoalListPage(),
      },
    );
  }
}