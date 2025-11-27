import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:runsafe/features/goals/data/repositories/weekly_goal_repository.dart';
import 'package:runsafe/features/alerts/data/repositories/safety_alert_repository.dart';
import 'package:runsafe/features/routes/data/repositories/waypoint_repository.dart'; 
import 'package:runsafe/features/routes/data/repositories/running_route_repository.dart'; 
import 'package:runsafe/features/profile/data/repositories/profile_repository.dart'; 
import 'package:runsafe/features/onboarding/presentation/pages/home_screen.dart';
import 'package:runsafe/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:runsafe/features/onboarding/presentation/pages/privacy_policy_screen.dart';
import 'package:runsafe/features/onboarding/presentation/pages/splash_screen.dart';
import 'package:runsafe/features/goals/presentation/pages/weekly_goal_list_page.dart';
import 'package:runsafe/features/alerts/presentation/pages/safety_alert_list_page.dart';
import 'package:runsafe/features/routes/presentation/pages/waypoint_list_page.dart';
import 'package:runsafe/features/routes/presentation/pages/running_route_list_page.dart'; 
import 'package:runsafe/core/utils/app_colors.dart';

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
        ChangeNotifierProvider(
          create: (context) => SafetyAlertRepository()..loadAlerts(),
        ),
        ChangeNotifierProvider(
          create: (context) => WaypointRepository()..loadWaypoints(),
        ),
        ChangeNotifierProvider(
          create: (context) => RunningRouteRepository()..loadRoutes(),
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
        '/safety-alerts': (context) => const SafetyAlertListPage(),
        '/waypoints': (context) => const WaypointListPage(),
        '/running-routes': (context) => const RunningRouteListPage(),
      },
    );
  }
}