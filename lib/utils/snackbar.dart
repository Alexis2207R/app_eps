import 'package:flutter/material.dart';
import 'package:app_eps/config/themes/colors_extension.dart';

enum SnackBarType { success, destructive, warning, info }

/// Muestra un SnackBar con un mensaje obligatorio, el color y duracion opcionales.
///
/// Debe ser llamado dentro de un BuildContext.
void snackBar(BuildContext context, String message, {SnackBarType? type, Duration? duration}) {
  final appColors = Theme.of(context).extension<ColorsExtension>();
  Color? snackBarColor;
  Color? snackBarForeground;

  switch (type) {
    case SnackBarType.success:
      snackBarColor = appColors?.success;
      snackBarForeground = appColors?.successForeground;
      break;
    case SnackBarType.destructive:
      snackBarColor = appColors?.destructive;
      snackBarForeground = appColors?.destructiveForeground;
      break;
    case SnackBarType.warning:
      snackBarColor = appColors?.warning;
      snackBarForeground = appColors?.warningForeground;
      break;
    case SnackBarType.info:
      snackBarColor = appColors?.info;
      snackBarForeground = appColors?.infoForeground;
      break;
    default:
      snackBarColor = null;
      snackBarForeground = null;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: snackBarForeground),
      ),
      backgroundColor: snackBarColor,
      duration: duration ?? const Duration(seconds: 3),
    ),
  );
}
