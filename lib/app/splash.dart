import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = false;
  bool _hasPermission = true;
  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    // Animación inicial del logo
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _isVisible = true);
    });

    // ✅ Verificar y pedir permisos primero
    final granted = await _checkAndRequestAllPermissions();

    if (!granted) {
      if (mounted) {
        setState(() => _hasPermission = false);
      }
      return;
    }

    await _checkLocalSessionAndNavigate();
  }

  Future<bool> _checkAndRequestAllPermissions() async {
    // 1. Manejo específico para Android
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      // La línea que fallaba ahora está dentro del bloque condicional
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      // print('DEBUG SDK: Dispositivo ejecutándose en Android SDK $sdkInt');

      final permissionsToRequest = <Permission>[
        Permission.camera,
      ];

      // Lógica para Almacenamiento/Galería: (Mantenemos tu lógica de Android)
      if (sdkInt >= 33) {
        permissionsToRequest.add(Permission.photos);
        permissionsToRequest.add(Permission.manageExternalStorage);
      } else if (sdkInt >= 30) {
        permissionsToRequest.add(Permission.storage);
        permissionsToRequest.add(Permission.manageExternalStorage);
      } else {
        permissionsToRequest.add(Permission.storage);
      }

      // 1. Solicitar los permisos relevantes
      final statuses = await permissionsToRequest.request();

      // 2. Comprobar si los permisos CRÍTICOS fueron concedidos
      final cameraGranted = statuses[Permission.camera]?.isGranted == true;

      bool storageMediaGranted = false;

      // Verificación detallada de los permisos de Almacenamiento/Media
      if (sdkInt >= 33) {
        final photosStatus = statuses[Permission.photos]?.isGranted == true;
        final manageStatus = await Permission.manageExternalStorage.isGranted;
        storageMediaGranted = photosStatus || manageStatus;
        // print('DEBUG PERM. (SDK $sdkInt): Photos: $photosStatus, ManageExternalStorage: $manageStatus');
      } else if (sdkInt >= 30) {
        final storageStatus = statuses[Permission.storage]?.isGranted == true;
        final manageStatus = await Permission.manageExternalStorage.isGranted;
        storageMediaGranted = storageStatus || manageStatus;
        // print('DEBUG PERM. (SDK $sdkInt): Storage: $storageStatus, ManageExternalStorage: $manageStatus');
      } else {
        storageMediaGranted = statuses[Permission.storage]?.isGranted == true;
      }

      // print('DEBUG RESULTADO: Cámara concedida: $cameraGranted, Almacenamiento/Media concedido: $storageMediaGranted');

      // Retornamos el resultado específico de Android
      return storageMediaGranted && cameraGranted;
    } else {
      // 2. Manejo para plataformas NO Android (Windows, Web, iOS, etc.)
      // En Windows y otras plataformas de escritorio/web, no hay permisos de "SDK"
      // ni la necesidad de gestionar "Scoped Storage". Asumimos que la operación
      // de guardado a nivel de aplicación (sandbox) siempre tendrá permiso.
      // print('DEBUG: Plataforma no Android. Saltando verificación de permisos de Android.');
      return true; // Asumimos que el permiso siempre está "concedido" para continuar
    }
  }

  Future<void> _checkLocalSessionAndNavigate() async {
    final String? token = await storage.read(key: 'access_token');
    String nextRoute = '/login';

    if (token != null && token.isNotEmpty) {
      nextRoute = '/home';
    }

    await Future.delayed(const Duration(milliseconds: 3500));

    if (mounted) {
      Navigator.pushReplacementNamed(context, nextRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          // Positioned.fill(
          //   child: Container(color: Colors.white),
          // ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    colorScheme.secondary,
                    colorScheme.primary,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          // Animación del logo de la marca en el centro
          if (!_hasPermission)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning, color: Colors.amber, size: 64),
                  const SizedBox(height: 20),
                  const Text(
                    '⚠️ No se otorgó permiso de almacenamiento.\n'
                    'Es necesario para guardar los datos localmente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await openAppSettings(); // 👈 abre configuración del sistema
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text("Abrir configuración"),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      setState(() => _hasPermission = true);
                      await _initApp(); // 👈 reintentar
                    },
                    child: const Text("Intentar de nuevo"),
                  ),
                ],
              ),
            )
          else
            // Animación del logo mientras carga
            Center(
              child: AnimatedOpacity(
                opacity: _isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeIn,
                child: SizedBox(
                  height: 450,
                  child: Image.asset(
                    'assets/images/splash.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: colorScheme.primary,
                        alignment: Alignment.center,
                        child: Text(
                          'LOGO',
                          style: TextStyle(color: colorScheme.surface),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
