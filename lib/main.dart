import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/library_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
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
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _onNav(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(onNavTap: _onNav),
          const UploadScreen(),
          const LibraryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: SkwBottomNav(
        currentIndex: _index,
        onTap: _onNav,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    if (_index == 0 || _index == 3) {
      return AppBar(
          toolbarHeight: 0,
          elevation: 0,
          backgroundColor: AppColors.background);
    }
    final titles = ['', 'Nouveau QCM', 'Bibliothèque', 'Mon profil'];
    return AppBar(
      title: Text(titles[_index]),
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: [
        if (_index == 1)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.orangeLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.orange.withOpacity(0.2), width: 0.5),
              ),
              child: const Icon(Icons.settings_outlined,
                  size: 16, color: AppColors.orange),
            ),
          ),
      ],
    );
  }
}
