// 1. AÑADIR LA IMPORTACIÓN DE SYNCSFUSION
import 'package:app_eps/config/constants.dart';
import 'package:pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data'; // Necesario para Uint8List
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http; // 🆕 Necesario para la API
import 'package:permission_handler/permission_handler.dart'; // 🆕 Necesario para la descarga
import 'package:pdf/widgets.dart' as pw;
import 'package:app_eps/utils/snackbar.dart';

// 1. Añadimos los argumentos al constructor
class CadastralRecordPdf extends StatefulWidget {
  final bool load;
  final String? sucursalId;
  final String? nroInscripcion;

  const CadastralRecordPdf({
    super.key,
    required this.load,
    this.sucursalId,
    this.nroInscripcion,
  });

  @override
  State<CadastralRecordPdf> createState() => _CadastralRecordPdfState();
}

class _CadastralRecordPdfState extends State<CadastralRecordPdf> {
  // Path al archivo temporal que usa el visor PDF
  String? localTempPath;
  // Bytes del PDF descargado para la descarga final
  Uint8List? pdfBytes;
  bool isLoading = true;

  // URL base de la API
  final String _baseUrl = '$apiUrl/app/actualizacion/ficha_catastral.php';

  @override
  void initState() {
    super.initState();
    // 🆕 Cambiamos el nombre de la función para reflejar la carga desde API
    loadPdfFromApi();
  }

  // 🆕 Función para cargar y convertir (si es necesario)
  Future<void> loadPdfFromApi() async {
    if (widget.sucursalId == null || widget.nroInscripcion == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = '$_baseUrl?nroinscripcion=${widget.nroInscripcion}&codsuc=${widget.sucursalId}';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 🆕 1. Detección del tipo de contenido
        final contentType = response.headers['content-type'] ?? '';

        if (contentType.contains('application/pdf') || contentType.contains('octet-stream')) {
          // La respuesta es PDF: Procede como antes.
          pdfBytes = response.bodyBytes;
        } else if (contentType.contains('text/html') || response.body.trim().startsWith('<')) {
          // La respuesta es HTML o potencialmente HTML. ¡Debemos convertir!
          // print('Detectado HTML, iniciando conversión a PDF.');

          // Obtenemos el texto HTML
          final htmlContent = response.body;

          // 🆕 LLAMADA A LA FUNCIÓN DE CONVERSIÓN
          pdfBytes = await _convertHtmlToPdfBytes(htmlContent);
        } else {
          throw Exception('Tipo de contenido inesperado: $contentType. Se esperaba PDF o HTML.');
        }

        // 2. Procede a guardar el archivo temporal (sea PDF original o PDF convertido)
        if (pdfBytes != null) {
          final dir = await getTemporaryDirectory();
          final namePdf = 'catastral_${widget.nroInscripcion}_${DateTime.now().microsecondsSinceEpoch}.pdf';
          final file = File('${dir.path}/$namePdf');

          await file.writeAsBytes(pdfBytes!, flush: true);

          setState(() {
            localTempPath = file.path;
            isLoading = false;
          });
        } else {
          throw Exception('Conversión de HTML a PDF fallida.');
        }
      } else {
        throw Exception('Fallo al cargar el documento. Código de estado: ${response.statusCode}');
      }
    } catch (e) {
      // ... tu manejo de errores ...
    }
  }

// 🆕 Función de conversión: Crea un PDF básico a partir del HTML de la respuesta
// Nota: Esta función es MUY básica. Si tu HTML tiene tablas, imágenes o estilos complejos,
// necesitarás una librería más avanzada (como un servicio web) o usar el paquete pdf
// para construir manualmente el diseño.
  Future<Uint8List> _convertHtmlToPdfBytes(String htmlContent) async {
    final pdf = pw.Document();

    // Extraer el texto simple del HTML (MÉTODO BÁSICO)
    // Nota: Una mejor solución sería usar el paquete 'html' para parsear y obtener widgets.
    final textContent = htmlContent
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ') // Eliminar etiquetas HTML y entidades
        .replaceAll(RegExp(r'\s+'), ' ') // Reducir espacios múltiples
        .trim();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              // Utilizamos el texto extraído del HTML
              textContent,
              style: const pw.TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // 🆕 Función para descargar el PDF a una ubicación permanente
  Future<void> _downloadPdf() async {
    if (pdfBytes == null) {
      snackBar(context, 'El PDF aún no está cargado.');
      return;
    }

    // 1. Solicitar permiso de almacenamiento (esencial en Android/iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) snackBar(context, 'Permiso de almacenamiento denegado. No se puede guardar el archivo.');
        return;
      }
    }

    try {
      // Usamos getApplicationDocumentsDirectory() como ubicación persistente
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'FichaCatastral_${widget.nroInscripcion}.pdf';
      final savePath = '${directory.path}/$fileName';
      final file = File(savePath);

      // 2. Escribir los bytes en el archivo de destino
      await file.writeAsBytes(pdfBytes!, flush: true);

      if (mounted) {
        snackBar(context, 'PDF descargado con éxito en: $savePath');
      }
    } catch (e) {
      if (mounted) {
        snackBar(context, 'Error al guardar el PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. MENSAJE DE VALIDACIÓN: Si faltan parámetros
    if (widget.sucursalId == null || widget.nroInscripcion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Catastro')),
        body: const Center(
          child: Text(
            'Por favor, **seleccione un catastro**.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.blueGrey),
          ),
        ),
      );
    }

    // 2. Construcción del Widget cuando hay parámetros
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Inscripción: ${widget.nroInscripcion}'),
        backgroundColor: Colors.blueGrey,
        actions: [
          // BOTÓN DE DESCARGA: Solo visible si el PDF se cargó
          if (localTempPath != null && !isLoading)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadPdf,
              tooltip: 'Descargar PDF',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localTempPath != null
              // 3. VISUALIZADOR DE PDF: SfPdfViewer.file
              ? SfPdfViewer.file(File(localTempPath!))
              : const Center(
                  child: Text(
                    'Error: No se pudo cargar el PDF desde la API.',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
    );
  }
}
