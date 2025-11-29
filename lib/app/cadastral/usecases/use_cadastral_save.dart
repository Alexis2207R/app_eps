// import 'dart:developer';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_eps/config/constants.dart';

Future<Map<String, dynamic>> useCadastralSave({required cadastral}) async {
  final Map<String, dynamic> dataToSend = {
    'app': true,
    ...cadastral,
  };

  try {
    final Future<http.Response> responseFuture = http.post(
      Uri.parse('$apiUrl/app/actualizacion/guardar.php'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(dataToSend),
    );

    final response = await responseFuture.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        throw TimeoutException('La solicitud al servidor ha tardado demasiado.');
      },
    );
    // log('Código de estado (HTTP): ${response.statusCode}');
    // log('Respuesta cruda del servidor: ${response.body}');

    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (responseBody['status'] == 'error') {
      throw Exception(responseBody['message']);
    }

    final apiData = responseBody['data'];

    if (apiData is Map && apiData.containsKey('nroinscripcion') && apiData.containsKey('nroficha')) {
      return {
        'nroinscripcion': apiData['nroinscripcion'],
        'nroficha': apiData['nroficha'],
      };
    } else {
      throw Exception('La sincronizacion fallo.');
    }
  } on TimeoutException {
    throw Exception('Error de conexión a internet.');
  } on FormatException {
    throw Exception('Error: Respuesta del servidor no es JSON válido.');
  } on Exception catch (e) {
    throw Exception(e.toString().replaceFirst('Exception: ', ''));
  }
}
