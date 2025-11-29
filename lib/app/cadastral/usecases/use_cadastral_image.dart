import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CadastralImageLogic {
  static const _imageDirName = 'cadastral_images';
  static final ImagePicker _picker = ImagePicker();

  // Obtiene el directorio base para guardar las imágenes
  static Future<Directory> _getImagesDirectory(String localId) async {
    final directory = await getApplicationDocumentsDirectory();
    final cadastralDir = Directory('${directory.path}/$_imageDirName/$localId');

    if (!await cadastralDir.exists()) {
      await cadastralDir.create(recursive: true);
    }
    return cadastralDir;
  }

  // Carga todas las rutas de imagen para un catastro
  static Future<List<String>> loadImages(String localId) async {
    try {
      final dir = await _getImagesDirectory(localId);
      final files = await dir.list().toList();
      return files.whereType<File>().map((f) => f.path).toList();
    } catch (e) {
      return [];
    }
  }

  // Función auxiliar para guardar el archivo
  static Future<String?> _savePickedFile(String localId, XFile pickedFile) async {
    final Directory dir = await _getImagesDirectory(localId);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final String newPath = '${dir.path}/$fileName';

    // Mueve (o copia) la imagen temporal a la carpeta de la aplicación
    final File localImage = await File(pickedFile.path).copy(newPath);

    return localImage.path;
  }

  // 📸 Opción 1: Tomar foto (Cámara)
  static Future<String?> takeImage(String localId) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return null;
    return _savePickedFile(localId, pickedFile);
  }

  // 🖼️ Opción 2: Cargar desde galería
  static Future<String?> pickFromGallery(String localId) async {
    // Usamos pickImage, NO pickMultiImage, para asegurar una sola selección
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;
    return _savePickedFile(localId, pickedFile);
  }

  // Elimina una imagen dada su ruta
  static Future<void> deleteImage(String imagePath) async {
    final file = File(imagePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
