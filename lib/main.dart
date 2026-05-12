import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'models/user.dart' as app_user;
import 'screens/auth_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/parent_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SkwiltiApp(),
    ),
  );
}

class SkwiltiApp extends StatelessWidget {
  const SkwiltiApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skwilti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});
  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    print('🔵 _init() démarré');
    await context.read<AppState>().init();
    print('🟢 _init() terminé');
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Consumer<AppState>(
      builder: (context, appState, _) => _getHome(appState),
    );
  }

  Widget _getHome(AppState state) {
    if (!state.isAuthenticated) return const AuthScreen();
    final user = state.currentUser;
    if (user == null) return const AuthScreen();
    switch (user.role) {
      case app_user.UserRole.teacher:
        return const TeacherDashboard();
      case app_user.UserRole.student:
        return const StudentDashboard();
      case app_user.UserRole.parent:
        return const ParentDashboard();
      case app_user.UserRole.admin:
        return const AdminDashboard();
      default:
        return const AuthScreen();
    }
  }
}