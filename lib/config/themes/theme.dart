import 'package:flutter/material.dart';
// Importa los archivos de tema individuales.
import 'package:app_eps/config/themes/light.dart';
import 'package:app_eps/config/themes/dark.dart';

/// Clase que encapsula la definición de los temas claro y oscuro de la aplicación.
class AppTheme {
  // Proporciona acceso al tema claro a través de una función estática.
  static ThemeData lightTheme() {
    return buildLightTheme();
  }

  // Proporciona acceso al tema oscuro a través de una función estática.
  static ThemeData darkTheme() {
    return buildDarkTheme();
  }
}
