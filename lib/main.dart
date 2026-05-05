import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'models/user.dart';
import 'screens/auth_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/parent_dashboard.dart';
import 'screens/admin_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return MaterialApp(
          title: 'Skwilti',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: _getHome(appState),
        );
      },
    );
  }

  Widget _getHome(AppState state) {
    if (!state.isAuthenticated) return const AuthScreen();
    final user = state.currentUser;
    if (user == null) return const AuthScreen();
    switch (user.role) {
      case UserRole.teacher: return const TeacherDashboard();
      case UserRole.student: return const StudentDashboard();
      case UserRole.parent:  return const ParentDashboard();
      case UserRole.admin:   return const AdminDashboard();
    }
  }
}
