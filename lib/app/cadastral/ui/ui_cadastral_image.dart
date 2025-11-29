import 'dart:io';
import 'package:app_eps/app/cadastral/services/service_cadastral_local_image.dart';
import 'package:app_eps/app/cadastral/type/type_cadastral_image.dart';
import 'package:app_eps/config/themes/colors_extension.dart';
import 'package:app_eps/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UiCadastralImage extends StatefulWidget {
  final String localId;
  final String nroInscripcion;
  final String sucursal;

  const UiCadastralImage({
    super.key,
    required this.localId,
    required this.nroInscripcion,
    required this.sucursal,
  });

  @override
  State<UiCadastralImage> createState() => _UiCadastralImageState();
}

class _UiCadastralImageState extends State<UiCadastralImage> {
  List<CadastralImage> _images = [];
  bool _isLoading = false;
  final int _maxImages = 5;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  // Carga las imágenes (con metadatos)
  Future<void> _loadImages() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _images = await cadastralImageService.loadImages(widget.localId);
    } catch (e) {
      if (mounted) {
        snackBar(context, 'Error al cargar metadatos de imágenes: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Añadir una imagen (cámara o galería)
  Future<void> _addImage(ImageSource source) async {
    if (_images.length >= _maxImages) {
      snackBar(context, 'Límite de $_maxImages imágenes alcanzado.');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final newImage = await cadastralImageService.addImage(widget.localId, source);
      if (newImage != null) {
        await _loadImages(); // Recargar la lista para actualizar la UI
        snackBar(context, 'Imagen agregada localmente (Pendiente de sincronizar).');
      }
    } catch (e) {
      if (mounted) snackBar(context, 'Error al añadir imagen: $e');
      // print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Sincronizar (subir) una imagen
  Future<void> _synchronizeImage(CadastralImage image) async {
    final connection = await Connectivity().checkConnectivity();
    if (connection == ConnectivityResult.none) {
      snackBar(context, 'No hay conexión a internet.');
      return;
    }
    if (image.isSynchronized) return;

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await cadastralImageService.synchronizeImage(
        widget.localId,
        widget.sucursal, // Asegúrate de que este dato es correcto
        widget.nroInscripcion,
        image,
      );
      await _loadImages(); // Recargar para mostrar estado Sincronizado
      snackBar(context, 'Imagen sincronizada con éxito.', type: SnackBarType.success);
    } catch (e) {
      if (mounted) snackBar(context, e.toString().replaceFirst('Exception: ', ''), type: SnackBarType.destructive);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Eliminar una imagen (local y remoto)
  Future<void> _deleteImage(CadastralImage image, String codsuc, String nroInscripcion) async {
    final connection = await Connectivity().checkConnectivity();
    if (image.isSynchronized && connection == ConnectivityResult.none) {
      snackBar(context, 'No se puede eliminar una imagen sincronizada sin conexión a internet.', type: SnackBarType.destructive);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await cadastralImageService.deleteImage(widget.localId, image, codsuc, nroInscripcion);
      await _loadImages(); // Recargar para actualizar la lista
      snackBar(context, 'Imagen eliminada con éxito.', type: SnackBarType.success);
    } catch (e) {
      // Muestra el mensaje de advertencia si falló la eliminación remota
      if (mounted) snackBar(context, e.toString().replaceFirst('Exception: ', ''), type: SnackBarType.warning);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🆕 Función para abrir la imagen en pantalla completa
  void _openFullScreenImage(CadastralImage image) {
    Navigator.of(context).push(
      // Usar PageRouteBuilder para una transición más fluida/personalizada
      PageRouteBuilder(
        opaque: false, // Permite que el fondo sea transparente
        barrierColor: Colors.black,
        pageBuilder: (BuildContext context, _, __) {
          // El widget que se muestra a pantalla completa
          return FullScreenImageViewer(
            imagePath: image.path,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<ColorsExtension>();
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        Navigator.pop(context, true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestor de Imágenes'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          final File file = File(image.path);

                          // Estado y color
                          final bool isSync = image.isSynchronized;
                          final Color? statusColor = isSync ? appColors?.successBase : appColors?.warningBase;

                          return GestureDetector(
                            // 🆕 Añadir GestureDetector
                            onTap: () => _openFullScreenImage(image), // 🆕 Llama a la función de zoom al hacer clic
                            child: GridTile(
                              header: GridTileBar(
                                backgroundColor: Colors.black45,
                                leading: Icon(
                                  isSync ? Icons.cloud_done : Icons.cloud_upload,
                                  color: statusColor,
                                  size: 16,
                                ),
                                title: Text(
                                  image.status,
                                  style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              footer: GridTileBar(
                                backgroundColor: Colors.black45,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    // Botón 1: Sincronizar (solo si está Pendiente)
                                    if (!isSync)
                                      IconButton(
                                        icon: const Icon(Icons.sync, color: Colors.blueAccent),
                                        onPressed: _isLoading ? null : () => _synchronizeImage(image),
                                        tooltip: 'Sincronizar Imagen',
                                      ),
                                    // Botón 2: Eliminar (siempre disponible localmente, con restricción si está sync)
                                    IconButton(
                                      icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                                      onPressed: _isLoading
                                          ? null
                                          : () => _deleteImage(
                                                image,
                                                widget.sucursal,
                                                widget.nroInscripcion,
                                              ),
                                      tooltip: 'Eliminar Imagen',
                                    ),
                                  ],
                                ),
                              ),
                              child: file.existsSync()
                                  ? Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey.shade300,
                                      child: const Center(child: Text('Archivo no encontrado')),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Imágenes subidas: ${_images.length} / $_maxImages',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _images.length < _maxImages ? () => _addImage(ImageSource.gallery) : null,
                            icon: const Icon(Icons.photo_library, size: 24),
                            label: const Text('Abrir galería'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _images.length < _maxImages ? () => _addImage(ImageSource.camera) : null,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Tomar foto'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// 🆕 Nuevo Widget para la vista de imagen a pantalla completa
class FullScreenImageViewer extends StatelessWidget {
  final String imagePath;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final File file = File(imagePath);
    if (!file.existsSync()) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Imagen no disponible.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // El widget principal de la imagen centrada
          Center(
            child: InteractiveViewer(
              // Permite hacer zoom y arrastrar
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(file),
            ),
          ),
          // Botón de cerrar (la 'x') en la esquina superior derecha
          Positioned(
            top: 40, // Ajustar según la barra de estado
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Cerrar Imagen',
            ),
          ),
        ],
      ),
    );
  }
}
