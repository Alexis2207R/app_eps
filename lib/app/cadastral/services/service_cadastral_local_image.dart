import 'dart:io';
import 'dart:convert';
import 'package:app_eps/app/cadastral/type/type_cadastral_image.dart';
import 'package:app_eps/config/constants.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

// URL de la API de sincronización
const String _apiBaseUrl = '$apiUrl/app/actualizacion/guardar_imagen.php';

class ServiceCadastralLocalImage {
  static const _folderName = 'eps/image';
  static const _metaFileName = 'images_meta.json';
  static final ImagePicker _picker = ImagePicker();

  // 1. Obtiene el directorio para la carpeta localId (donde se guarda el JSON y las imágenes)
  Future<Directory> _getImagesLocalIdDirectory(String localId) async {
    // ⚠️ ATENCIÓN: Esta ruta es la equivalente al ejemplo anterior, pero REQUIERE PERMISOS
    // DE ALMACENAMIENTO (storage permissions) en la aplicación para funcionar en Android.
    final baseDir = Directory('/storage/emulated/0/Documents/$_folderName');

    final localIdDir = Directory('${baseDir.path}/$localId');

    // Crea el directorio si no existe
    if (!await localIdDir.exists()) {
      await localIdDir.create(recursive: true);
    }
    return localIdDir;
  }

  // 2. Lee el archivo JSON de metadatos (estado)
  Future<List<CadastralImage>> _loadMetaData(String localId) async {
    final dir = await _getImagesLocalIdDirectory(localId);
    final metaFile = File('${dir.path}/$_metaFileName');

    if (!await metaFile.exists()) {
      return [];
    }

    try {
      final String content = await metaFile.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => CadastralImage.fromJson(json)).toList();
    } catch (e) {
      // Manejar error de corrupción del JSON
      // print('Error al leer metadata: $e');
      return [];
    }
  }

  // 3. Guarda el archivo JSON de metadatos
  Future<void> _saveMetaData(String localId, List<CadastralImage> images) async {
    final dir = await _getImagesLocalIdDirectory(localId);
    final metaFile = File('${dir.path}/$_metaFileName');
    final jsonList = images.map((img) => img.toJson()).toList();
    await metaFile.writeAsString(jsonEncode(jsonList));
  }

  // 🆕 Función para comprimir una imagen temporal a una nueva ruta
  Future<String> _compressAndSaveImage(String sourcePath, String targetPath) async {
    // 1. Asegurar que el directorio de destino exista (Buena práctica)
    final targetFile = File(targetPath);
    final targetDir = targetFile.parent;
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    try {
      // ⬇️ 1. INTENTO PRINCIPAL: Usar Compresión Nativa (Funciona en Mobile)
      // print('DEBUG: Intentando compresión nativa...');

      final result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: 75,
        format: CompressFormat.jpeg,
        minWidth: 1000,
        minHeight: 1000,
        keepExif: false,
      );

      // Si result es null, forzamos una excepción para ir al catch (o la manejamos aquí)
      if (result == null) {
        // Lanzamos una excepción forzada si la librería falla silenciosamente (devuelve null)
        throw Exception('Fallo la compresion de la imagen.');
      }

      // print('DEBUG: Compresión nativa exitosa.');
      return result.path;
    } catch (e) {
      // ⬇️ 2. FALLBACK: Si la compresión falla (típico en Desktop), solo copiamos el archivo
      // print('ADVERTENCIA: Falló la compresión ($e). Recurriendo a copia directa.');

      // Si la compresión falla, la copiamos directamente para Desktop
      try {
        final resultFile = await File(sourcePath).copy(targetPath);
        // print('DEBUG: Copia directa (Desktop Fallback) exitosa.');
        return resultFile.path;
      } catch (copyError) {
        // Si incluso la copia falla, es un error grave de permisos o ruta
        // print('ERROR CRÍTICO: La copia de respaldo también falló: $copyError');
        throw Exception('Fallo la gestión de la imagen (compresión y copia).');
      }
    }
  }

  // ----------------------------------------------------
  // MÉTODOS PÚBLICOS
  // ----------------------------------------------------

  // Carga todas las imágenes (con metadatos) para un catastro
  Future<List<CadastralImage>> loadImages(String localId) async {
    return await _loadMetaData(localId);
  }

  // Seleccionar foto y guardarla localmente
  Future<CadastralImage?> addImage(String localId, ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return null;

    final dir = await _getImagesLocalIdDirectory(localId);
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String fileName = '$timestamp.jpg';
    final String newPath = '${dir.path}/$fileName';

    // 🆕 Comprimir y Guardar imagen física
    // El archivo original se comprime y se guarda en newPath,
    // el archivo temporal de pickedFile.path se borra automáticamente por el picker
    final String compressedPath = await _compressAndSaveImage(
      pickedFile.path,
      newPath,
    );

    // Actualizar metadatos
    final List<CadastralImage> images = await _loadMetaData(localId);
    final newImage = CadastralImage(
      path: compressedPath, // Usar la ruta del archivo comprimido
      name: fileName,
      status: 'Pendiente', // Siempre Pendiente al crear
    );
    images.add(newImage);
    await _saveMetaData(localId, images);

    return newImage;
  }

  // ☁️ Sincronizar (Insertar) imagen al servidor
  Future<CadastralImage> synchronizeImage(String localId, String codsuc, String nroInscripcion, CadastralImage image) async {
    if (image.isSynchronized) {
      throw Exception('La imagen ya está sincronizada.');
    }

    final file = File(image.path);
    if (!await file.exists()) {
      throw Exception('Archivo de imagen no encontrado localmente.');
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(_apiBaseUrl));
      request.fields['codsuc'] = codsuc;
      request.fields['Op'] = '1'; // 1 para insertar
      request.fields['nroinscripcion'] = nroInscripcion;

      // Adjuntar el archivo
      request.files.add(await http.MultipartFile.fromPath(
        'imagen1',
        file.path,
        filename: image.name,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        // print(responseBody);
        if (responseBody['status'] == 'success') {
          // Actualizar estado local
          image.status = 'Sincronizado';
          image.codFichaImagen = responseBody['codfichaimagen'].toString();

          final images = await _loadMetaData(localId);
          final index = images.indexWhere((img) => img.path == image.path);
          if (index != -1) {
            images[index] = image; // Reemplazar la imagen actualizada
            await _saveMetaData(localId, images);
          }
          return image;
        } else {
          throw Exception(responseBody['message'] ?? 'Error desconocido en la API.');
        }
      } else {
        throw Exception('Error de servidor: ${response.statusCode}');
      }
    } catch (e) {
      // Si falla, mantenemos el estado local como 'Pendiente'
      throw Exception('Fallo la sincronización: $e');
    }
  }

  // 🗑️ Eliminar imagen (Local y Remoto)
  Future<void> deleteImage(
    String localId,
    CadastralImage image,
    String codsuc,
    String nroInscripcion,
  ) async {
    bool remoteDeletionSuccess = true;

    // 1. Intentar eliminar del servidor si está sincronizada
    if (image.isSynchronized && image.codFichaImagen != null) {
      try {
        var request = http.MultipartRequest('POST', Uri.parse(_apiBaseUrl));
        request.fields['Op'] = '2'; // 2 para eliminar
        request.fields['codfichaimagen'] = image.codFichaImagen!;
        request.fields['codsuc'] = codsuc;
        request.fields['nroinscripcion'] = nroInscripcion;

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (jsonDecode(response.body)['status'] != 'success') {
          // Si la eliminación remota falla, lanza error, pero no bloquea la eliminación local
          remoteDeletionSuccess = false;
          // print('${jsonDecode(response.body)['message']}');
        }
        // print(jsonDecode(response.body));
      } catch (e) {
        remoteDeletionSuccess = false;
        // print('Advertencia: Falló la comunicación con el servidor para eliminar: $e');
      }
    }

    // 2. Eliminar archivo local
    final file = File(image.path);
    if (!image.isSynchronized) {
      await file.delete();
    }
    if (await file.exists() && remoteDeletionSuccess == true) {
      await file.delete();
    }

    // 3. Eliminar de los metadatos y guardar
    if (remoteDeletionSuccess == true) {
      final List<CadastralImage> images = await _loadMetaData(localId);
      images.removeWhere((img) => img.path == image.path);
      await _saveMetaData(localId, images);
    }

    if (!remoteDeletionSuccess) {
      throw Exception('Falló la eliminación. Intente de nuevo cuando tenga conexión.');
    }
  }

  Future<int> countSynchronizedImages(String localId) async {
    final List<CadastralImage> images = await _loadMetaData(localId);
    // Contar las imágenes cuyo estado es 'Sincronizado'
    final int count = images.where((img) => img.isSynchronized).length;
    return count;
  }
}

// Reemplazar el antiguo use_cadastral_image.dart con una referencia al nuevo servicio
final cadastralImageService = ServiceCadastralLocalImage();
