import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<String?> getAccessToken() async {
  const storage = FlutterSecureStorage();
  return await storage.read(key: 'access_token');
}

void redirectLogin(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
    (Route<dynamic> route) => false,
  );
}
