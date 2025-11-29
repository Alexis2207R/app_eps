import 'package:app_eps/app/cadastral/type/type_cadastral_list.dart';
import 'package:app_eps/app/cadastral/services/service_cadastral_local_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Recibe el ID del filtro seleccionado (0=Todos, 1=Sincronizados, 2=Pendientes)
Future<List<CadastralList>> useCadastralList({int? typeId = 0, String sucursalId = ''}) async {
  const FlutterSecureStorage storageSession = FlutterSecureStorage();
  final storage = ServiceCadastralLocalStorage();
  final String? userId = await storageSession.read(key: 'user_id');

  if (userId == null || userId.isEmpty) {
    return [];
  }

  // 1. Carga datos de todos los archivos JSON del directorio
  final List<Map<String, dynamic>> records = await storage.loadAllCadastrals();

  // 2. Mapea cada JSON a un objeto CadastralList
  List<CadastralList> cadastrals = records.map((json) => CadastralList.fromJson(json)).toList();

  // El primer filtro de todos: solo listar los registros donde empadronador == userId.
  cadastrals = cadastrals.where((cadastral) {
    // El campo 'empadronador' debe ser igual al userId del usuario logueado
    return cadastral.empadronador == userId;
  }).toList();

  // 3. APLICAR FILTRO
  if (typeId != 0 && typeId != null) {
    cadastrals = cadastrals.where((cadastral) {
      final bool isSynced = cadastral.synchronized;

      if (typeId == 1) {
        return isSynced; // 1: Sincronizados
      } else if (typeId == 2) {
        return !isSynced; // 2: Pendientes
      }
      return true;
    }).toList();
  }

  if (sucursalId.isNotEmpty) {
    cadastrals = cadastrals.where((cadastral) {
      // El campo 'sucursal' en CadastralList (que viene del JSON)
      final String cadastralSucursalId = cadastral.sucursal.toString();
      return cadastralSucursalId == sucursalId;
    }).toList();
  }

  // 4. ORDENAR (Más reciente a más antiguo)
  // Asumiendo que 'localId' contiene el timestamp de creación (cadastral_1762206237700).
  // Extraemos el timestamp del final del 'localId' para ordenar.
  cadastrals.sort((a, b) {
    // Función para extraer el timestamp (parte numérica al final)
    int parseTimestamp(String? localId) {
      if (localId == null) return 0;
      final parts = localId.split('_');
      if (parts.length > 1) {
        return int.tryParse(parts.last) ?? 0;
      }
      return 0;
    }

    final tsA = parseTimestamp(a.localId);
    final tsB = parseTimestamp(b.localId);

    // b.compareTo(a) para ordenar de Mayor a Menor (Más reciente primero)
    return tsB.compareTo(tsA);
  });

  return cadastrals;
}
