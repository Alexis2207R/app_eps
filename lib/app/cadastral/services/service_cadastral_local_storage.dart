import 'dart:io';
import 'dart:convert';

class ServiceCadastralLocalStorage {
  static const _folderName = 'eps/data';
  // Obtiene el directorio base: documents/eps/data
  Future<Directory> _getDirectory() async {
    final epsDataDir = Directory('/storage/emulated/0/Documents/$_folderName');

    // Crea el directorio si no existe
    if (!await epsDataDir.exists()) {
      await epsDataDir.create(recursive: true);
    }
    return epsDataDir;
  }

  /// Guarda un registro catastral en un archivo JSON.
  /// Si [localId] es nulo, crea un nuevo archivo con un ID único.
  /// Si [localId] existe, sobrescribe el archivo existente.
  Future<String> saveCadastral(Map<String, dynamic> data, String? localId) async {
    final dir = await _getDirectory();

    // Genera un ID local único si es un registro nuevo
    final id = localId ?? 'cadastral_${DateTime.now().millisecondsSinceEpoch}';

    data['localId'] = id;

    final file = File('${dir.path}/$id.json');
    await file.writeAsString(jsonEncode(data));

    return id;
  }

  /// Carga un registro catastral específico usando su ID.
  Future<Map<String, dynamic>?> loadCadastral(String localId) async {
    try {
      final dir = await _getDirectory();
      final file = File('${dir.path}/$localId.json');

      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        throw Exception('No se encontró el archivo $localId.json');
      }
    } catch (e) {
      throw Exception('Error al leer el archivo: $e');
    }
  }

  /// Carga TODOS los registros catastrales
  Future<List<Map<String, dynamic>>> loadAllCadastrals() async {
    final dir = await _getDirectory();
    final List<Map<String, dynamic>> cadastrals = [];

    await for (final entity in dir.list()) {
      // Asegúrate de que sea un archivo JSON
      if (entity is File && entity.path.endsWith('.json')) {
        final content = await entity.readAsString();
        cadastrals.add(jsonDecode(content) as Map<String, dynamic>);
      }
    }
    return cadastrals;
  }
}
