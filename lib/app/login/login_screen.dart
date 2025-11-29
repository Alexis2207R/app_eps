import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:app_eps/config/responsive/responsive_width.dart';
import 'package:app_eps/utils/snackbar.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const LoginScreen({super.key, required this.toggleTheme});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;

  List<Map<String, dynamic>> _localUsersData = [];

  @override
  void initState() {
    super.initState();
    _loadLocalUsers();
  }

  Future<void> _loadLocalUsers() async {
    try {
      final String response = await rootBundle.loadString('assets/data/users.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _localUsersData = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (mounted) {
        snackBar(context, 'Error en la carga de usuarios, comuniquese con soporte técnico.', type: SnackBarType.destructive);
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_localUsersData.isEmpty) {
      if (mounted) {
        snackBar(context, 'Error: Datos de usuario no cargados. Intente reiniciar la app.', type: SnackBarType.destructive);
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final dniInput = _dniController.text.trim();
      final passwordInput = _passwordController.text.trim();

      // 1. Buscar usuario por DNI
      final user = _localUsersData.firstWhere(
        (u) => u['dni'] == dniInput,
        orElse: () => {},
      );

      // 2. Validar credenciales (DNI debe existir y DNI == Contraseña)
      if (user.isNotEmpty && dniInput == passwordInput) {
        final String id = user['id'];
        final String dni = user['dni'];
        final String name = user['name'];
        final String position = user['position'];

        // Guardamos los datos de la sesión local en FlutterSecureStorage
        await storage.write(key: 'access_token', value: 'mock_token_$dni');
        await storage.write(key: 'user_id', value: id);
        await storage.write(key: 'user_dni', value: dni);
        await storage.write(key: 'user_name', value: name);
        await storage.write(key: 'user_position', value: position);

        if (mounted) {
          snackBar(context, 'Bienvenido, $name!', type: SnackBarType.success);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        if (mounted) {
          snackBar(context, 'Usuario (DNI) o contraseña incorrectos', type: SnackBarType.destructive);
        }
      }
    } catch (e) {
      if (mounted) {
        snackBar(context, 'Error inesperado durante el login: ${e.toString()}', type: SnackBarType.destructive);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Brightness currentBrightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ResponsiveWidth(
                sm: 6 / 12,
                md: 5 / 12,
                lg: 4 / 12,
                xl: 3 / 12,
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Card(
                    elevation: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Iniciar Sesión',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _dniController,
                            decoration: InputDecoration(
                              labelText: 'DNI',
                              prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(8),
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'El DNI es obligatorio';
                              }
                              return null;
                            },
                            onFieldSubmitted: (value) => _login(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(8),
                              FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es obligatoria';
                              }
                              return null;
                            },
                            onFieldSubmitted: (value) => _login(),
                          ),
                          const SizedBox(height: 32),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _isLoading || _localUsersData.isEmpty ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                  elevation: 8,
                                ),
                                child: const Text('Acceder'),
                              ),
                              if (_isLoading || _localUsersData.isEmpty) const CircularProgressIndicator(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: widget.toggleTheme,
              tooltip: 'Cambiar tema',
              child: Icon(
                currentBrightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
