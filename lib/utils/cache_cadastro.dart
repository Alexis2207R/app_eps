import 'dart:convert';
import 'dart:io';

class CacheCadastro {
  static const _folderName = 'eps';
  static const _fileName = 'catastro_cache.json';
  static bool _isSaving = false;

  static Future<String> _getCacheFilePath() async {
    final epsDir = Directory('/storage/emulated/0/Documents/$_folderName');

    if (!(await epsDir.exists())) {
      await epsDir.create(recursive: true);
    }

    return '${epsDir.path}/$_fileName';
  }

  /// Guarda el contenido del formulario en JSON
  static Future<void> save(Map<String, dynamic> data) async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      final path = await _getCacheFilePath();
      final file = File(path);

      // Sobrescribe el archivo completamente
      final sink = file.openWrite(mode: FileMode.write);
      sink.write(jsonEncode(data));
      await sink.flush();
      await sink.close();
    } finally {
      _isSaving = false;
    }
  }

  /// Carga el JSON si existe
  static Future<Map<String, dynamic>?> load() async {
    final path = await _getCacheFilePath();
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();

      if (content.trim().isEmpty) {
        return null;
      }

      return jsonDecode(content);
    }
    return null;
  }

  /// Borra el cache
  static Future<void> clear() async {
    final path = await _getCacheFilePath();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
