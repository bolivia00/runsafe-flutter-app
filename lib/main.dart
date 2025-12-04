import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <-- ADICIONADO
import 'package:flutter_dotenv/flutter_dotenv.dart'; // <-- ADICIONADO

import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/core/services/safety_alerts_local_dao.dart';
import 'package:runsafe/core/services/running_routes_local_dao.dart';
import 'package:runsafe/core/services/waypoints_local_dao.dart';
import 'package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart';
import 'package:runsafe/features/goals/data/repositories/weekly_goals_repository_impl.dart';
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';
import 'package:runsafe/features/alerts/infrastructure/remote/safety_alerts_remote_datasource_supabase.dart';
import 'package:runsafe/features/alerts/infrastructure/repositories/safety_alerts_repository_impl_remote.dart';
import 'package:runsafe/features/alerts/presentation/providers/safety_alerts_provider.dart';
import 'package:runsafe/features/alerts/data/mappers/safety_alert_mapper.dart';
import 'package:runsafe/features/routes/infrastructure/remote/running_routes_remote_datasource_supabase.dart';
import 'package:runsafe/features/routes/infrastructure/repositories/running_routes_repository_impl_remote.dart';
import 'package:runsafe/features/routes/presentation/providers/running_routes_provider.dart';
import 'package:runsafe/features/routes/data/mappers/running_route_mapper.dart';
import 'package:runsafe/features/routes/infrastructure/remote/waypoints_remote_datasource_supabase.dart';
import 'package:runsafe/features/routes/infrastructure/repositories/waypoints_repository_impl_remote.dart';
import 'package:runsafe/features/routes/presentation/providers/waypoints_provider.dart';
import 'package:runsafe/features/routes/data/mappers/waypoint_mapper.dart';
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

Future<void> main() async {
  // Necessário quando usamos inicialização assíncrona no main()
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Carregar variáveis de ambiente
  await dotenv.load(fileName: ".env");

  // 🔥 Inicialização do Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ProfileRepository()..loadPhotoPath(),
        ),
        ChangeNotifierProvider(
          create: (context) => WeeklyGoalsProvider(
            WeeklyGoalsRepositoryImpl(
              WeeklyGoalsLocalDao(StorageService()),
            ),
          )..load('default-user'),
        ),
        ChangeNotifierProvider(
          create: (context) => SafetyAlertsProvider(
            SafetyAlertsRepositoryImplRemote(
              SafetyAlertsLocalDaoSharedPrefs(),
              SupabaseSafetyAlertsRemoteDatasource(Supabase.instance.client),
              SafetyAlertMapper(), // Injeta mapper para conversão DTO ↔ Entity
            ),
          )..loadAlerts(),
        ),
        // Antigo repository - mantido para compatibilidade com formulários
        ChangeNotifierProvider(
          create: (context) => WaypointRepository()..loadWaypoints(),
        ),
        // Novo provider com sincronização remota
        ChangeNotifierProvider(
          create: (context) => WaypointsProvider(
            WaypointsRepositoryImplRemote(
              WaypointsLocalDaoSharedPrefs(),
              SupabaseWaypointsRemoteDatasource(Supabase.instance.client),
              WaypointMapper(), // Injeta mapper para conversão DTO ↔ Entity
            ),
          )..loadWaypoints(),
        ),
        // Antigo repository - mantido para compatibilidade com formulários
        ChangeNotifierProvider(
          create: (context) => RunningRouteRepository()..loadRoutes(),
        ),
        // Novo provider com sincronização remota
        ChangeNotifierProvider(
          create: (context) => RunningRoutesProvider(
            RunningRoutesRepositoryImplRemote(
              RunningRoutesLocalDaoSharedPrefs(),
              SupabaseRunningRoutesRemoteDatasource(Supabase.instance.client),
              RunningRouteMapper(WaypointMapper()),
            ),
          )..loadRoutes(),
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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.emerald),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
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
