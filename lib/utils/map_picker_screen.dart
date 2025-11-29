import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:app_eps/utils/snackbar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ImmutableBuffer, rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// --- CLASE PARA LEER MBTILES (NECESARIA) ---
// Adaptada del código de la primera respuesta.
class MbTilesTileProvider extends TileProvider {
  final String mbtilesPath;
  late final Future<Database> _database;

  MbTilesTileProvider({
    required this.mbtilesPath,
    required int maxZoom,
    required int minZoom,
  }) {
    _database = openDatabase(mbtilesPath, readOnly: true);
  }

  @override
  ImageProvider getImage(TileCoordinates coords, TileLayer options) {
    final z = coords.z.toInt();
    final x = coords.x.toInt();
    final y = (pow(2, z) - 1 - coords.y.toInt()).toInt();

    return _MbTilesImageProvider(
      db: _database,
      z: z,
      x: x,
      y: y,
    );
  }
}
// --- FIN CLASE MBTILES ---

class _MbTilesImageProvider extends ImageProvider<_MbTilesImageProvider> {
  final Future<Database> db;
  final int z;
  final int x;
  final int y;

  const _MbTilesImageProvider({
    required this.db,
    required this.z,
    required this.x,
    required this.y,
  });

  @override
  Future<_MbTilesImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_MbTilesImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _MbTilesImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(_loadAsync(decode));
  }

  Future<ImageInfo> _loadAsync(ImageDecoderCallback decode) async {
    final database = await db;

    final result = await database.query(
      'tiles',
      columns: ['tile_data'],
      where: 'zoom_level = ? AND tile_column = ? AND tile_row = ?',
      whereArgs: [z, x, y],
    );

    if (result.isEmpty) {
      throw Exception("Tile no encontrado: Z=$z X=$x Y=$y");
    }

    final Uint8List bytes = result.first['tile_data'] as Uint8List;

    final ImmutableBuffer buffer = await ImmutableBuffer.fromUint8List(bytes);

    final ImageDescriptor descriptor = await ImageDescriptor.encoded(buffer);

    final Codec codec = await descriptor.instantiateCodec();

    final FrameInfo frameInfo = await codec.getNextFrame();

    return ImageInfo(image: frameInfo.image);
  }

  @override
  bool operator ==(Object other) {
    return other is _MbTilesImageProvider && other.z == z && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(z, x, y);
}

class MapPickerScreen extends StatefulWidget {
  final String sucursalName;
  final String initialCoordinates;
  final String fieldName;

  const MapPickerScreen({
    super.key,
    required this.sucursalName,
    required this.initialCoordinates,
    required this.fieldName,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();

  Future<LatLng> _getCenterFromMBTiles(String path) async {
    final db = await openDatabase(path, readOnly: true);

    final result = await db.query(
      'metadata',
      where: 'name = ?',
      whereArgs: ['center'],
      limit: 1,
    );

    if (result.isNotEmpty) {
      final String value = result.first['value'].toString();
      final parts = value.split(',');

      if (parts.length >= 2) {
        final lon = double.parse(parts[0]);
        final lat = double.parse(parts[1]);
        return LatLng(lat, lon);
      }
    }

    // Si no existe metadata.center, usamos bounds
    final boundsResult = await db.query(
      'metadata',
      where: 'name = ?',
      whereArgs: ['bounds'],
      limit: 1,
    );

    if (boundsResult.isNotEmpty) {
      final b = boundsResult.first['value'].toString().split(',');
      final minLon = double.parse(b[0]);
      final minLat = double.parse(b[1]);
      final maxLon = double.parse(b[2]);
      final maxLat = double.parse(b[3]);

      return LatLng(
        (minLat + maxLat) / 2,
        (minLon + maxLon) / 2,
      );
    }

    // Fallback
    return const LatLng(-6.0, -78.0);
  }
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _tappedPoint;
  String? _mbtilesPath;
  LatLng? _mapCenter;
  LatLng? _userLocation;
  bool _userInsideMap = false;
  double? _minLon, _minLat, _maxLon, _maxLat;

  // Mapa de coordenadas iniciales para centrar el mapa (Lon, Lat)
  // Usaremos el centro de las sucursales como punto de inicio por defecto
  // final Map<String, LatLng> _initialCenters = {
  //   'Jaen': LatLng(-6.2660, -79.8800), // Ejemplo Jaén
  //   'Bellavista': LatLng(-6.2570, -78.1170), // Ejemplo Bellavista
  //   'San Ignacio': LatLng(-5.1500, -79.0000), // Ejemplo San Ignacio
  // };

  @override
  void initState() {
    super.initState();
    _loadMBTilesAsset();
    _parseInitialCoordinates();
  }

  // Parsea las coordenadas iniciales para el marcador
  void _parseInitialCoordinates() {
    try {
      final parts = widget.initialCoordinates.split(',');
      if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        // Formato: Longitud, Latitud (Lon, Lat)
        final lon = double.parse(parts[0]);
        final lat = double.parse(parts[1]);
        _tappedPoint = LatLng(lat, lon);
      }
    } catch (_) {
      _tappedPoint = null; // Ignorar si hay un error de parseo
    }
  }

  // Carga el archivo MBTiles desde assets al directorio temporal
  Future<void> _loadMBTilesAsset() async {
    final fileName = '${widget.sucursalName.toLowerCase().replaceAll(' ', '_')}.mbtiles';

    final assetPath = 'assets/mbtiles/$fileName';
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';

    if (!await File(path).exists()) {
      try {
        final data = await rootBundle.load(assetPath);
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
      } catch (e) {
        if (mounted) {
          snackBar(context, 'Error al cargar el mapa de ${widget.sucursalName}: $e', type: SnackBarType.destructive);
        }
        return;
      }
    }

    // Leer centro desde el MBTiles
    final center = await widget._getCenterFromMBTiles(path);

    // Leer bounds exactos del MBTiles
    final db = await openDatabase(path, readOnly: true);
    final boundsResult = await db.query(
      'metadata',
      where: 'name = ?',
      whereArgs: ['bounds'],
      limit: 1,
    );

    if (boundsResult.isNotEmpty) {
      final parts = boundsResult.first['value'].toString().split(',');
      _minLon = double.parse(parts[0]);
      _minLat = double.parse(parts[1]);
      _maxLon = double.parse(parts[2]);
      _maxLat = double.parse(parts[3]);
    }

    if (mounted) {
      setState(() {
        _mbtilesPath = path;
        _mapCenter = center;
      });
    }

    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return;

    final pos = await Geolocator.getCurrentPosition();

    final userLatLng = LatLng(pos.latitude, pos.longitude);

    // Validar si está dentro del mapa
    bool inside = false;
    if (_minLat != null) {
      inside = (userLatLng.latitude >= _minLat! && userLatLng.latitude <= _maxLat! && userLatLng.longitude >= _minLon! && userLatLng.longitude <= _maxLon!);
    }

    if (mounted) {
      setState(() {
        _userLocation = inside ? userLatLng : null;
        _userInsideMap = inside;
      });
    }

    if (!inside && mounted) {
      snackBar(context, "Tu ubicación está fuera del mapa cargado.", type: SnackBarType.destructive);
    }

    // Ubicación falsa SOLO para pruebas
    // if (!inside && mounted) {
    //   final fakeLocation = LatLng(-5.142840, -78.999278);

    //   setState(() {
    //     _userLocation = fakeLocation;
    //     _userInsideMap = true;
    //   });

    //   snackBar(context, "Tu ubicación está fuera del mapa. Mostrando ubicación simulada.", type: SnackBarType.info);

    //   return;
    // }
  }

  // Función para obtener las coordenadas al tocar
  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    setState(() {
      _tappedPoint = latlng;
    });
  }

  // Retorna la coordenada al formulario principal
  void _selectCoordinate() {
    if (_tappedPoint == null) {
      snackBar(context, 'Por favor, selecciona un punto en el mapa.', type: SnackBarType.destructive);
      return;
    }
    // Formato estricto: Longitud, Latitud
    final result = '${_tappedPoint!.longitude},${_tappedPoint!.latitude}';
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    if (_mbtilesPath == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Mapa de ${widget.sucursalName}')),
        body: const Center(
            child: CircularProgressIndicator(
          value: null,
        )),
      );
    }

    // final initialCenter = _tappedPoint ?? _mapCenter ?? const LatLng(-6.0, -78.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sucursalName),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _selectCoordinate,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _tappedPoint == null ? "Toque el mapa para seleccionar una coordenada" : "Seleccionado: ${_tappedPoint!.longitude.toStringAsFixed(6)}, ${_tappedPoint!.latitude.toStringAsFixed(6)}",
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (_userInsideMap)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Tu ubicación: ${_userLocation!.longitude.toStringAsFixed(6)}, ${_userLocation!.latitude.toStringAsFixed(6)}",
                style: TextStyle(fontSize: 14, color: Colors.blue[700]),
              ),
            ),
          FlutterMap(
            options: MapOptions(
              initialZoom: 15,
              minZoom: 15,
              maxZoom: 19,
              initialCenter: _mapCenter ?? const LatLng(-6.0, -78.0),

              // 🔥 ESTE ES EL IMPORTANTE
              onTap: (tapPosition, latlng) {
                _handleTap(tapPosition, latlng);
              },
            ),
            children: [
              TileLayer(
                tileProvider: MbTilesTileProvider(
                  mbtilesPath: _mbtilesPath!,
                  minZoom: 15,
                  maxZoom: 19,
                ),
                minZoom: 15,
                maxZoom: 19,
              ),
              if (_tappedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80,
                      height: 80,
                      point: _tappedPoint!,
                      child: Icon(
                        Icons.close_rounded,
                        color: widget.fieldName == 'agua'
                            ? Colors.green
                            : widget.fieldName == 'desague'
                                ? Colors.red
                                : Colors.grey,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_tappedPoint != null)
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Lon: ${_tappedPoint!.longitude.toStringAsFixed(6)}\n"
                  "Lat: ${_tappedPoint!.latitude.toStringAsFixed(6)}",
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
