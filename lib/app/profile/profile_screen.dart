import 'package:app_eps/config/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:app_eps/config/themes/colors_extension.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final storage = const FlutterSecureStorage();
  String _dni = '';
  String _name = 'Cargando...';
  String _position = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final dni = await storage.read(key: 'user_dni');
    final name = await storage.read(key: 'user_name');
    final position = await storage.read(key: 'user_position');

    if (mounted) {
      setState(() {
        _dni = dni ?? 'N/A';
        _name = name ?? 'Usuario Desconocido';
        _position = position ?? 'No Asignado';
      });
    }
  }

  void _logout(BuildContext context) async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'user_dni');
    await storage.delete(key: 'user_name');
    await storage.delete(key: 'user_position');

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<ColorsExtension>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            color: Theme.of(context).cardColor,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 24),
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: colorScheme.primary,
                    child: Icon(Icons.person, size: 80, color: colorScheme.onPrimary),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: appColors?.standard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                      child: Text(
                        'Ip: $apiUrl',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                  Card(
                    color: appColors?.standard,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                      child: Text(
                        _position,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DNI: $_dni',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar Sesión'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appColors?.destructive,
                      foregroundColor: appColors?.destructiveForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
