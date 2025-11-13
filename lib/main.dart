import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:runsafe/domain/repositories/weekly_goal_repository.dart';
// import 'package:runsafe/domain/repositories/safety_alert_repository.dart'; // REMOVIDO POR ENQUANTO
import 'package:runsafe/domain/repositories/waypoint_repository.dart'; 
import 'package:runsafe/repositories/profile_repository.dart'; 
import 'package:runsafe/screens/home_screen.dart';
import 'package:runsafe/screens/onboarding_screen.dart';
import 'package:runsafe/screens/privacy_policy_screen.dart';
import 'package:runsafe/screens/splash_screen.dart';
import 'package:runsafe/screens/weekly_goal_list_page.dart';
// import 'package:runsafe/screens/safety_alert_list_page.dart'; // REMOVIDO POR ENQUANTO
import 'package:runsafe/screens/waypoint_list_page.dart';
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
        // ChangeNotifierProvider( // REMOVIDO POR ENQUANTO
        //   create: (context) => SafetyAlertRepository()..loadAlerts(),
        // ),
        ChangeNotifierProvider(
          create: (context) => WaypointRepository()..loadWaypoints(),
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
      // Mantenha seu tema completo aqui
      theme: ThemeData(
         useMaterial3: true,
         colorScheme: ColorScheme.fromSeed(seedColor: AppColors.emerald),
         // ... (seu tema)
      ),
      initialRoute: '/',
      routes: {
        '/':(context) => const SplashScreen(), 
        '/onboarding': (context) => const OnboardingScreen(),
        '/privacy': (context) => const PrivacyPolicyScreen(),
        '/home': (context) => const HomeScreen(),
        '/weekly-goals': (context) => const WeeklyGoalListPage(),
        // '/safety-alerts': (context) => const SafetyAlertListPage(), // REMOVIDO POR ENQUANTO
        '/waypoints': (context) => const WaypointListPage(),
      },
    );
  }
}