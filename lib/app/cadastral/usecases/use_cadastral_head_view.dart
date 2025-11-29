import 'dart:async';

import 'package:app_eps/app/cadastral/type/type_cadastral_head_view.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_eps/config/constants.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

Future<CadastralHeadView> useCadastralHeadView(String branchId, String? recordCode, String? meterCode) async {
  final connectivityResult = await Connectivity().checkConnectivity();
  if (connectivityResult == ConnectivityResult.none) {
    throw Exception('Sin conexión a Internet. Conéctate a Wi-Fi o datos móviles.');
  }

  final String recordParam = (recordCode ?? '').trim();
  final String meterParam = (meterCode ?? '').trim();

  try {
    final responseFuture = http.get(
      Uri.parse('$apiUrl/app/datos.php?codsuc=$branchId&nroinscripcion=$recordParam&nromedidor=$meterParam'),
      headers: {
        'Content-Type': 'application/json',
      },
    );

    final response = await responseFuture.timeout(
      const Duration(seconds: 60),
      onTimeout: () {
        // Esto se ejecuta si la API no responde en 60 segundos
        throw TimeoutException('La solicitud al servidor ha tardado demasiado.');
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Error del servidor. Comunicate con soporte técnico.');
    }

    final Map<String, dynamic> responseBody = jsonDecode(response.body);

    if (responseBody['mensaje'] == 'No se encontraron resultados para tu consulta.') {
      throw Exception(responseBody['mensaje']);
    }

    return CadastralHeadView.fromJson(responseBody);
  } on TimeoutException {
    throw Exception('Error de conexión a internet.');
  } on http.ClientException catch (_) {
    throw Exception('Sin conexión a Internet. Conéctate a Wi-Fi o datos móviles.');
  } on Exception catch (e) {
    throw Exception('Error inesperado: ${e.toString()}');
  }
}
