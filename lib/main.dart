import 'package:flutter/material.dart';
import 'package:app_eps/config/themes/theme.dart';
// page
import 'package:app_eps/app/splash.dart';
import 'package:app_eps/app/login/login_screen.dart';
import 'package:app_eps/app/layout.dart';
import 'package:app_eps/app/profile/profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeKey = 'isDarkMode';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestStoragePermission();
  runApp(const AppOtass());
}

Future<void> _requestStoragePermission() async {
  // Primero verificamos el permiso normal de almacenamiento
  var storageStatus = await Permission.storage.status;
  if (!storageStatus.isGranted) {
    await Permission.storage.request();
  }

  // En Android 11+ (SDK 30+) se necesita MANAGE_EXTERNAL_STORAGE
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }

  // Si el usuario rechazó permanentemente
  if (await Permission.storage.isPermanentlyDenied || await Permission.manageExternalStorage.isPermanentlyDenied) {
    await openAppSettings();
  }
}

class AppOtass extends StatefulWidget {
  const AppOtass({super.key});

  @override
  State<AppOtass> createState() => _AppOtassState();
}

class _AppOtassState extends State<AppOtass> with WidgetsBindingObserver {
  ThemeMode? _themeMode;
  @override
  void initState() {
    super.initState();
    // Añadimos el observador para detectar el tema del sistema
    WidgetsBinding.instance.addObserver(this);
    _loadThemePreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Escucha cambios en las configuraciones del sistema (como el tema oscuro)
  @override
  void didChangePlatformBrightness() {
    if (_themeMode == null) {
      // Si el usuario nunca ha guardado una preferencia, actualiza según el sistema
      _loadThemePreference();
    }
  }

  /// Carga la preferencia del tema guardada o usa la del sistema
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();

    // Obtener la preferencia guardada (null si no existe)
    final savedIsDark = prefs.getBool(_themeKey);

    // 1. Obtener el brillo actual del sistema (Dark o Light)
    final platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;

    ThemeMode newThemeMode;

    if (savedIsDark != null) {
      // 2. Si hay una preferencia guardada, úsala.
      newThemeMode = savedIsDark ? ThemeMode.dark : ThemeMode.light;
    } else {
      // 3. Si NO hay una preferencia guardada, usa la del sistema.
      newThemeMode = platformBrightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;
    }

    if (mounted) {
      setState(() {
        _themeMode = newThemeMode;
      });
    }
  }

  void _toggleTheme() async {
    final currentIsDark = _themeMode == ThemeMode.dark;
    final newThemeMode = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, !currentIsDark);

    if (mounted) {
      setState(() {
        _themeMode = newThemeMode;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_themeMode == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      title: 'App de Ingenieria la OTASS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: _themeMode!,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => Layout(toggleTheme: _toggleTheme),
        '/login': (context) => LoginScreen(toggleTheme: _toggleTheme),
        '/user_profile': (context) => const ProfileScreen(),
      },
    );
  }
}
