import 'dart:convert';

import 'package:app_eps/app/cadastral/data/sectores_comerciales.dart';
import 'package:app_eps/app/cadastral/services/service_cadastral_local_storage.dart';
import 'package:app_eps/app/cadastral/usecases/use_cadastral_save.dart';
import 'package:app_eps/config/themes/colors_extension.dart';
import 'package:app_eps/utils/cache_cadastro.dart';
import 'package:app_eps/utils/map_picker_screen.dart';
import 'package:app_eps/utils/snackbar.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Data para el formulario
import 'package:app_eps/app/cadastral/data/abastecimientos_complementario.dart';
import 'package:app_eps/app/cadastral/data/accesorios_medidor.dart';
import 'package:app_eps/app/cadastral/data/almacenamientos_complementario.dart';
import 'package:app_eps/app/cadastral/data/caracteristicas_conexion_agua.dart';
import 'package:app_eps/app/cadastral/data/caracteristicas_conexion_desague.dart';
import 'package:app_eps/app/cadastral/data/diametros_conexion_agua.dart';
import 'package:app_eps/app/cadastral/data/diametros_conexion_desague.dart';
import 'package:app_eps/app/cadastral/data/diametros_medidor.dart';
import 'package:app_eps/app/cadastral/data/estados_accesorio_medidor.dart';
import 'package:app_eps/app/cadastral/data/estados_caja_agua.dart';
import 'package:app_eps/app/cadastral/data/estados_caja_desague.dart';
import 'package:app_eps/app/cadastral/data/estados_marco_tapa_agua.dart';
import 'package:app_eps/app/cadastral/data/estados_medidor.dart';
import 'package:app_eps/app/cadastral/data/estados_tapa_caja_desague.dart';
import 'package:app_eps/app/cadastral/data/jardin_huertos_complementario.dart';
import 'package:app_eps/app/cadastral/data/marcas_medidor.dart';
import 'package:app_eps/app/cadastral/data/materiales_caja_agua.dart';
import 'package:app_eps/app/cadastral/data/materiales_caja_desague.dart';
import 'package:app_eps/app/cadastral/data/materiales_conexion_agua.dart';
import 'package:app_eps/app/cadastral/data/materiales_conexion_desague.dart';
import 'package:app_eps/app/cadastral/data/materiales_construccion.dart';
import 'package:app_eps/app/cadastral/data/materiales_marco_tapa_agua.dart';
import 'package:app_eps/app/cadastral/data/materiales_tapa_caja_desague.dart';
import 'package:app_eps/app/cadastral/data/opciones_agua_comite.dart';
import 'package:app_eps/app/cadastral/data/opciones_fugas_agua.dart';
import 'package:app_eps/app/cadastral/data/opciones_habitada.dart';
import 'package:app_eps/app/cadastral/data/opciones_piscina.dart';
import 'package:app_eps/app/cadastral/data/opciones_pozo_artesiano.dart';
import 'package:app_eps/app/cadastral/data/pavimentos_complementario.dart';
import 'package:app_eps/app/cadastral/data/responsables_predio.dart';
import 'package:app_eps/app/cadastral/data/saneamientos_complementario.dart';
import 'package:app_eps/app/cadastral/data/situaciones_conexion_agua.dart';
import 'package:app_eps/app/cadastral/data/situaciones_conexion_desague.dart';
import 'package:app_eps/app/cadastral/data/sucursales.dart';
import 'package:app_eps/app/cadastral/data/manzanas.dart';
import 'package:app_eps/app/cadastral/data/sectores.dart';
import 'package:app_eps/app/cadastral/data/tipos_construccion.dart';
import 'package:app_eps/app/cadastral/data/opciones_actividades.dart';
import 'package:app_eps/app/cadastral/data/tipos_predio.dart';
import 'package:app_eps/app/cadastral/data/tipos_servicio.dart';
import 'package:app_eps/app/cadastral/data/tipos_usuario.dart';
import 'package:app_eps/app/cadastral/data/tipos_vereda_complementario.dart';
import 'package:app_eps/app/cadastral/data/ubicaciones_caja_desague.dart';
import 'package:app_eps/app/cadastral/data/ubicaciones_caja_agua.dart';
import 'package:app_eps/app/cadastral/data/unidades_uso.dart';

// Datos de cabecera
import 'package:app_eps/app/cadastral/usecases/use_cadastral_head_view.dart';
import 'package:app_eps/app/cadastral/type/type_cadastral_head_view.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum FilterType { recordCode, meterCode }

class UiCadastralForm extends StatefulWidget {
  final String? localId;
  const UiCadastralForm({super.key, this.localId});

  @override
  State<UiCadastralForm> createState() => _UiCadastralFormState();
}

class _UiCadastralFormState extends State<UiCadastralForm> {
  final _formKey = GlobalKey<FormState>();

  // Lista de catastros
  final _localStorage = ServiceCadastralLocalStorage();

  // Estados de carga
  bool _isLoading = false;
  bool _isLoadingCache = false;
  bool _isFillingFromApi = false;

  // Almacenamiento local con json
  final _storage = ServiceCadastralLocalStorage();

  // Cargar datos del inicio de sesion
  final FlutterSecureStorage _storageSession = const FlutterSecureStorage();

  // Lista de usuarios
  List<Map<String, dynamic>> _localUsersData = [];

  // === Sección de busqueda ===
  final List<Map<String, dynamic>> _sucursales = sucursales;
  Map<String, dynamic>? _selectedSucursal = {'id': '', 'name': 'Seleccionar', 'coddistrito': '', 'codprovincia': ''};
  FilterType? _selectedFilterType;
  final TextEditingController _recordCodeController = TextEditingController();

  // === Datos del cliente ===
  final List<Map<String, dynamic>> _sectores = sectores;
  final List<Map<String, dynamic>> _manzanas = manzanas;

  Map<String, dynamic>? _selectedSector = {'id': '', 'sucursalId': '', 'name': 'Seleccionar'};
  Map<String, dynamic>? _selectedManzana = {"sucursalId": "", "sectorId": "", "id": "", "name": "Seleccionar"};

  List<Map<String, dynamic>> _filteredSectores = [];
  List<Map<String, dynamic>> _filteredManzanas = [];

  bool nuevoCliente = false;

  // Seccion 1
  final TextEditingController _nroFichaController = TextEditingController();

  // === Sección 2: Tipo de usuario===
  final List<Map<String, dynamic>> _tiposUsuario = tiposUsuario;
  int? _selectedtipoUsuario;

  // === Sección 3: Datos Generales del Usuario ===
  final TextEditingController _nroInscripcionController = TextEditingController();
  final TextEditingController _codigoCatastralController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _sectorComercialController = TextEditingController();

  // === Sección 4: Nuevo Código Catastral ===
  final TextEditingController _provinciaController = TextEditingController();
  final TextEditingController _distritoController = TextEditingController();
  final TextEditingController _zaController = TextEditingController();
  final TextEditingController _mzController = TextEditingController();
  final TextEditingController _loteController = TextEditingController();
  final TextEditingController _conexionController = TextEditingController();

  // === Sección 5: Datos Generales del Usuario (Registrados/No Registrados) ===
  final TextEditingController _nuevoNombreController = TextEditingController();
  final TextEditingController _nuevoDireccionController = TextEditingController();
  final List<Map<String, dynamic>> _sectoresComerciales = sectoresComerciales;
  Map<String, dynamic>? _selectedSectorComercial = {'sucursalId': '', 'id': '', 'name': 'Seleccionar'};
  List<Map<String, dynamic>> _filteredSectoresComerciales = [];

  // Seccion 6
  final List<Map<String, dynamic>> _tiposResponsablePredio = tiposResponsablePredio;
  int? _selectedTipoResponsablePredio;

  // Seccion 7
  final List<Map<String, dynamic>> _tiposConstruccion = tiposConstruccion;
  int? _selectedTipoConstruccion;
  final List<Map<String, dynamic>> _tiposPredio = tiposPredio;
  int? _selectedTipoPredio;
  final List<Map<String, dynamic>> _materialesConstruccion = materialesConstruccion;
  int? _selectedMaterialConstruccion;
  final List<Map<String, dynamic>> _tiposServicio = tiposServicio;
  int? _selectedTipoServicio;
  final TextEditingController _numeroPisosController = TextEditingController();
  final List<Map<String, dynamic>> _opcionesHabitada = opcionesHabitada;
  int? _selectedOpcionHabitada;
  final List<Map<String, dynamic>> _opcionesAguaComite = opcionesAguaComite;
  int? _selectedOpcionAguaComite;
  final TextEditingController _numeroPersonasController = TextEditingController();
  final TextEditingController _numeroFamiliasController = TextEditingController();
  final List<Map<String, dynamic>> _opcionesPiscina = opcionesPiscina;
  int? _selectedOpcionPiscina;
  final List<Map<String, dynamic>> _opcionesPozoArtesiano = opcionesPozoArtesiano;
  int? _selectedOpcionPozoArtesiano;
  final List<Map<String, dynamic>> _unidadesUso = unidadesUso;
  final List<Map<String, dynamic>> _opcionesActividades = opcionesActividades;
  final Map<int, bool> _usosSeleccionados = {};
  final Map<int, int?> _actividadesSeleccionadas = {};
  List<Map<String, dynamic>> arrayTarifas = [];

  void _agregarTarifa(int idUnidadUso, int idActividad) {
    _isFillingFromApi = true;
    setState(() {
      arrayTarifas.add({
        'idunidaduso': idUnidadUso,
        'idactividad': idActividad,
      });

      // limpiar checkbox y dropdown
      _usosSeleccionados[idUnidadUso] = false;
      _actividadesSeleccionadas[idUnidadUso] = null;
    });
    _isFillingFromApi = false;
  }

  void _eliminarTarifa(int index) {
    setState(() {
      arrayTarifas.removeAt(index);
    });
  }

  // Seccion 8
  final List<Map<String, dynamic>> _caracteristicasConexionAgua = caracteristicasConexionAgua;
  int? _selectedCaracteristicaConexionAgua;
  final List<Map<String, dynamic>> _diametrosConexionAgua = diametrosConexionAgua;
  int? _selectedDiametroConexionAgua;
  final List<Map<String, dynamic>> _materialesConexionAgua = materialesConexionAgua;
  int? _selectedMaterialConexionAgua;
  final List<Map<String, dynamic>> _situacionesConexionAgua = situacionesConexionAgua;
  int? _selectedSituacionConexionAgua;
  final List<Map<String, dynamic>> _opcionesFugaAgua = opcionesFugaAgua;
  int? _selectedOpcionFugaAgua;

  // Seccion 9
  final List<Map<String, dynamic>> _ubicacionesCajaAgua = ubicacionesCajaAgua;
  int? _selectedUbicacionCajaAgua;
  final TextEditingController _profundidadCajaAguaController = TextEditingController();
  final List<Map<String, dynamic>> _materialesCajaAgua = materialesCajaAgua;
  int? _selectedMaterialCajaAgua;
  final List<Map<String, dynamic>> _estadosCajaAgua = estadosCajaAgua;
  int? _selectedEstadoCajaAgua;

  // Seccion 10
  final List<Map<String, dynamic>> _materialesMarcoTapaAgua = materialesMarcoTapaAgua;
  int? _selectedMaterialMarcoTapaAgua;
  final List<Map<String, dynamic>> _estadosMarcoTapaAgua = estadosMarcoTapaAgua;
  int? _selectedEstadoMarcoTapaAgua;

  // Sección 11
  final TextEditingController _nroMedidorController = TextEditingController();
  final TextEditingController _lecturaMedidorController = TextEditingController();
  final List<Map<String, dynamic>> _marcasMedidor = marcasMedidor;
  int? _selectedMarcaMedidor;
  final List<Map<String, dynamic>> _diametrosConexionMedidor = diametrosConexionMedidor;
  int? _selectedDiametroConexionMedidor;
  final List<Map<String, dynamic>> _estadosMedidor = estadosMedidor;
  int? _selectedEstadoMedidor;
  final List<Map<String, dynamic>> _accesoriosMedidor = accesoriosMedidor;
  int? _selectedAccesorioMedidor;
  final List<Map<String, dynamic>> _estadosAccesorioMedidor = estadosAccesorioMedidor;
  int? _selectedEstadoAccesorioMedidor;

  // === Sección 12 ===
  final List<Map<String, dynamic>> _caracteristicasConexionDesague = caracteristicasConexionDesague;
  int? _selectedCaracteristicaConexionDesague;
  final List<Map<String, dynamic>> _diametrosConexionDesague = diametrosConexionDesague;
  int? _selectedDiametroConexionDesague;
  final List<Map<String, dynamic>> _materialesConexionDesague = materialesConexionDesague;
  int? _selectedMaterialConexionDesague;
  final List<Map<String, dynamic>> _situacionesConexionDesague = situacionesConexionDesague;
  int? _selectedSituacionConexionDesague;

  // === Sección 13 ===
  final List<Map<String, dynamic>> _ubicacionesCajaDesague = ubicacionesCajaDesague;
  int? _selectedUbicacionCajaDesague;
  final List<Map<String, dynamic>> _materialesCajaDesague = materialesCajaDesague;
  int? _selectedMaterialCajaDesague;
  final List<Map<String, dynamic>> _estadosCajaDesague = estadosCajaDesague;
  int? _selectedEstadoCajaDesague;

  // === Sección 14 ===
  final List<Map<String, dynamic>> _materialesTapaCajaDesague = materialesTapaCajaDesague;
  int? _selectedMaterialTapaCajaDesague;
  final List<Map<String, dynamic>> _estadosTapaCajaDesague = estadosTapaCajaDesague;
  int? _selectedEstadoTapaCajaDesague;

  // === Sección 15 ===
  final List<Map<String, dynamic>> _abastecimientosComplementario = abastecimientosComplementario;
  int? _selectedAbastecimientoComplementario;
  final List<Map<String, dynamic>> _jardinHuertosComplementario = jardinHuertosComplementario;
  int? _selectedJardinHuertoComplementario;
  final List<Map<String, dynamic>> _saneamientosComplementario = saneamientosComplementario;
  int? _selectedSaneamientoComplementario;
  final TextEditingController _horasAbastecimientoController = TextEditingController();
  final List<Map<String, dynamic>> _almacenamientosComplementario = almacenamientosComplementario;
  int? _selectedAlmacenamientoComplementario;
  final List<Map<String, dynamic>> _tiposVeredaComplementario = tiposVeredaComplementario;
  int? _selectedTipoVeredaComplementario;
  final List<Map<String, dynamic>> _pavimentosComplementario = pavimentosComplementario;
  int? _selectedPavimentoComplementario;

  // Seccion 16
  final TextEditingController _fronteraPredioController = TextEditingController();
  final TextEditingController _frontera2PredioController = TextEditingController();
  final TextEditingController _areaPredioController = TextEditingController();
  final TextEditingController _areaConstruidaController = TextEditingController();

  // Seccion 17
  final TextEditingController _cotaCnxApController = TextEditingController();
  final TextEditingController _cotaCnxAlcController = TextEditingController();
  final TextEditingController _longitudAguaController = TextEditingController();
  final TextEditingController _latitudAguaController = TextEditingController();
  final TextEditingController _longitudDesagueController = TextEditingController();
  final TextEditingController _latitudDesagueController = TextEditingController();

  // Seccion 18
  final TextEditingController _zonasPresionController = TextEditingController();

  // Seccion 19
  final TextEditingController _zonaAbastecimientoController = TextEditingController();

  // Seccion 20
  final TextEditingController _nuevoSectorComercialController = TextEditingController();

  // Seccion 21
  final TextEditingController _observacionesController = TextEditingController();

  // Seccion 22
  final _fechaEncuestaController = TextEditingController(
    text: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );

  // Seccion 23
  final TextEditingController _empadronadorController = TextEditingController();
  String? _empadronadorId;

  // Seccion 24
  List<Map<String, dynamic>> _supervisores = [];
  Map<String, dynamic>? _selectedSupervisor;

  // Seccion 25
  List<Map<String, dynamic>> _digitadores = [];
  Map<String, dynamic>? _selectedDigitador;

  // Seccion 26
  final _fechaDigitacionController = TextEditingController(
    text: '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );

  Future<void> _loadLocalUsers() async {
    try {
      _isFillingFromApi = true;
      final String response = await rootBundle.loadString('assets/data/users.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _localUsersData = data.cast<Map<String, dynamic>>();
        _supervisores = _localUsersData.where((user) => user['position'] == 'Supervisor').toList();
        final Map<String, dynamic> defaultSupervisorMap = {"id": "", "dni": "", "name": "Seleccionar", "position": ""};
        _supervisores.insert(0, defaultSupervisorMap);
        _digitadores = _localUsersData.where((user) => user['position'] == 'Digitador').toList();
        final Map<String, dynamic> defaultDigitadorMap = {"id": "", "dni": "", "name": "Seleccionar", "position": ""};
        _digitadores.insert(0, defaultDigitadorMap);
      });
    } catch (e) {
      if (mounted) {
        snackBar(context, 'Error en la carga de usuarios, comuniquese con soporte técnico.', type: SnackBarType.destructive);
      }
    } finally {
      _isFillingFromApi = false;
    }
  }

  Future<void> _loadEmpadronadorData() async {
    final userId = await _storageSession.read(key: 'user_id');
    final userName = await _storageSession.read(key: 'user_name');

    setState(() {
      _isLoadingCache = true;
    });

    if (userId != null && userName != null) {
      setState(() {
        _empadronadorId = userId;
        _empadronadorController.text = userName;
      });
    }

    setState(() {
      _isLoadingCache = false;
    });
    _saveCache();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingCache = true;
    });

    Map<String, dynamic> cached;

    if (widget.localId != null) {
      cached = await _storage.loadCadastral(widget.localId!) ?? {};
    } else {
      cached = await CacheCadastro.load() ?? {};
    }

    if (cached.isNotEmpty) {
      setState(() {
        // Datos principales
        final sucursalId = cached['sucursal'];
        if (sucursalId != '') {
          _selectedSucursal = _sucursales.firstWhere((sucursal) => sucursal['id'] == sucursalId);
          _filteredSectores = _sectores.where((s) => s['sucursalId'] == sucursalId).toList();
          _provinciaController.text = _selectedSucursal?['codprovincia']?.toString() ?? '';
          _distritoController.text = _selectedSucursal?['coddistrito']?.toString() ?? '';
        } else {
          _filteredSectores = [];
        }

        final sectorId = cached['sector'];
        if (sucursalId != '' && sectorId != '') {
          _selectedSector = _filteredSectores.firstWhere((sector) => sector['id'] == sectorId && sector['sucursalId'] == sucursalId);
          _filteredManzanas = _manzanas.where((m) => m['sucursalId'] == sucursalId && m['sectorId'] == sectorId.toString()).toList();
          _zaController.text = sectorId.toString();
          _zonaAbastecimientoController.text = '${_selectedSector?['id'] ?? ''}. ${_selectedSector?['name'] ?? ''}';
        } else {
          _filteredManzanas = [];
        }

        final manzanaId = cached['manzanas'];
        if (sucursalId != '' && sectorId != '' && manzanaId != '') {
          _selectedManzana = _filteredManzanas.firstWhere((manzana) => manzana['id'] == manzanaId && manzana['sectorId'] == sectorId.toString() && manzana['sucursalId'] == sucursalId);
          _mzController.text = _selectedManzana?['id']?.toString() ?? '';
        }

        nuevoCliente = cached['nuevo_cliente'] == 1 ? true : false;
        // Seccion 1
        _nroFichaController.text = cached['nroficha']?.toString() ?? '';
        // Seccion 2
        _selectedtipoUsuario = cached['tipousuario'];
        // Seccion 3
        _nroInscripcionController.text = cached['nroinscripcion']?.toString() ?? '';
        _codigoCatastralController.text = cached['codigo_cadastral']?.toString() ?? '';
        _nombreController.text = cached['nombre']?.toString() ?? '';
        _direccionController.text = cached['direccion']?.toString() ?? '';
        _sectorComercialController.text = cached['sectorcomercial']?.toString() ?? '';
        // Seccion 4
        _loteController.text = cached['lote']?.toString() ?? '';
        _conexionController.text = cached['sublote']?.toString() ?? '';
        // Seccion 5
        _nuevoNombreController.text = cached['propietario']?.toString() ?? '';
        _nuevoDireccionController.text = cached['direccion_ficha']?.toString() ?? '';
        final sectorComercialId = cached['codsector_comercial'];
        if (sucursalId != '') {
          _filteredSectoresComerciales = _sectoresComerciales.where((s) => s['sucursalId'] == sucursalId).toList();
        } else {
          _filteredSectoresComerciales = [];
        }
        if (sucursalId != '' && sectorComercialId != '') {
          _selectedSectorComercial = _filteredSectoresComerciales.firstWhere((sector) => sector['id'] == sectorComercialId && sector['sucursalId'] == sucursalId);
        }
        // Seccion 6
        _selectedTipoResponsablePredio = cached['tiporesponsable'];
        // Seccion 7
        _selectedTipoConstruccion = cached['tipoconstruccion'];
        _selectedTipoPredio = cached['tipopredio'];
        _selectedMaterialConstruccion = cached['tipomatconstruccion'];
        _selectedTipoServicio = cached['tiposervicio'];
        _numeroPisosController.text = cached['nropisos']?.toString() ?? '';
        _selectedOpcionHabitada = cached['habitada'] == true
            ? 1
            : cached['habitada'] == false
                ? 2
                : null;
        _selectedOpcionAguaComite = cached['agua_comite'] == true
            ? 1
            : cached['agua_comite'] == false
                ? 2
                : null;
        _numeroPersonasController.text = cached['nro_personas']?.toString() ?? '';
        _numeroFamiliasController.text = cached['nro_familias']?.toString() ?? '';
        _selectedOpcionPiscina = cached['piscina'];
        _selectedOpcionPozoArtesiano = cached['conpozo'];
        arrayTarifas = List<Map<String, dynamic>>.from(cached['tarifas']);
        // Seccion 8
        _selectedCaracteristicaConexionAgua = cached['caracteconexionagua'];
        _selectedDiametroConexionAgua = cached['diametrosagua'];
        _selectedMaterialConexionAgua = cached['tipomaterialagua'];
        _selectedSituacionConexionAgua = cached['situacionconexiongua'];
        _selectedOpcionFugaAgua = cached['fugasyatoros'];
        // Seccion 9
        _selectedUbicacionCajaAgua = cached['locacajaagua'];
        _profundidadCajaAguaController.text = cached['profundidad']?.toString() ?? '';
        _selectedMaterialCajaAgua = cached['tipocajaagua'];
        _selectedEstadoCajaAgua = cached['estadocajaagua'];
        // Seccion 10
        _selectedMaterialMarcoTapaAgua = cached['tipotapaagua'];
        _selectedEstadoMarcoTapaAgua = cached['estadotapaagua'];
        // Seccion 11
        _nroMedidorController.text = cached['nromedidor']?.toString() ?? '';
        _lecturaMedidorController.text = cached['lecturaultima'] == null ? '' : cached['lecturaultima'].toString();
        _selectedMarcaMedidor = cached['marcamedidor'];
        _selectedDiametroConexionMedidor = cached['diametrosmedidor'];
        _selectedEstadoMedidor = cached['estadomedidor'];
        _selectedAccesorioMedidor = cached['codaccesorio'];
        _selectedEstadoAccesorioMedidor = cached['estado_codaccesorio'];
        // Seccion 12
        _selectedCaracteristicaConexionDesague = cached['codcaracteconexiondesague'];
        _selectedDiametroConexionDesague = cached['diametrosdesague'];
        _selectedMaterialConexionDesague = cached['tipomaterialdesague'];
        _selectedSituacionConexionDesague = cached['codsituacionconexiondesague'];
        // Seccion 13
        _selectedUbicacionCajaDesague = cached['locacajadesague'];
        _selectedMaterialCajaDesague = cached['tipocajadesague'];
        _selectedEstadoCajaDesague = cached['estadocajadesague'];
        // Seccion 14
        _selectedMaterialTapaCajaDesague = cached['tipotapadesague'];
        _selectedEstadoTapaCajaDesague = cached['estadotapadesague'];
        // Seccion 15
        _selectedAbastecimientoComplementario = cached['tipoabastecimiento'];
        _selectedJardinHuertoComplementario = cached['codjardinhuerto'];
        _selectedSaneamientoComplementario = cached['codsaneamiento'];
        _horasAbastecimientoController.text = cached['horasabastecimiento'] == null ? '' : cached['horasabastecimiento'].toString();
        _selectedAlmacenamientoComplementario = cached['tipoalmacenaje'];
        _selectedTipoVeredaComplementario = cached['tipovereda'];
        _selectedPavimentoComplementario = cached['pavimentoagua'];
        // Seccion 16
        _fronteraPredioController.text = cached['frontera']?.toString() ?? '';
        _frontera2PredioController.text = cached['frontera2']?.toString() ?? '';
        _areaPredioController.text = cached['areapredio']?.toString() ?? '';
        _areaConstruidaController.text = cached['areaconstruida']?.toString() ?? '';
        // Seccion 17
        _cotaCnxApController.text = cached['cotacnxagua']?.toString() ?? '';
        _cotaCnxAlcController.text = cached['cotacnxdesague']?.toString() ?? '';
        _longitudAguaController.text = cached['longitud_agua']?.toString() ?? '';
        _latitudAguaController.text = cached['latitud_agua']?.toString() ?? '';
        _longitudDesagueController.text = cached['longitud_desague']?.toString() ?? '';
        _latitudDesagueController.text = cached['latitud_desague']?.toString() ?? '';
        // Seccion 18
        _zonasPresionController.text = cached['zonapresion']?.toString() ?? '';
        // Seccion 21
        _observacionesController.text = cached['observacionficha']?.toString() ?? '';
        // Seccion 22
        if (cached['fechaencuesta'] == null || cached['fechaencuesta'] == '') {
          _fechaEncuestaController.text = formatDate(DateTime.now());
        } else {
          _fechaEncuestaController.text = cached['fechaencuesta'];
        }
        // Seccion 24
        final supervisorId = cached['supervisor'] ?? '';
        _selectedSupervisor = _supervisores.firstWhere((supervisor) => supervisor['id'] == supervisorId);
        // Seccion 25
        final digitadorId = cached['digitador'] ?? '';
        _selectedDigitador = _digitadores.firstWhere((digitador) => digitador['id'] == digitadorId);
        // Seccion 26
        if (cached['fechadigitacion'] == null || cached['fechadigitacion'] == '') {
          _fechaDigitacionController.text = formatDate(DateTime.now());
        } else {
          _fechaDigitacionController.text = cached['fechadigitacion'];
        }
      });
    }

    setState(() {
      _isLoadingCache = false;
    });
  }

  void _saveCache() async {
    if (widget.localId != null) return;
    if (_isLoadingCache) return;
    print('hola');

    final data = {
      // Datos principales
      "sucursal": _selectedSucursal?['id'],
      "sector": _selectedSector?['id'] == '' ? '' : _selectedSector?['id'].toInt(),
      "manzanas": _selectedManzana?['id'],
      "nuevo_cliente": nuevoCliente == true ? 1 : 0,
      // Seccion 2
      "tipousuario": _selectedtipoUsuario,
      // Seccion 3
      "nroinscripcion": _nroInscripcionController.text,
      "codigo_cadastral": _codigoCatastralController.text,
      "nombre": _nombreController.text,
      "direccion": _direccionController.text,
      "sectorcomercial": _sectorComercialController.text,
      // Seccion 4
      "lote": _loteController.text,
      "sublote": _conexionController.text,
      // Seccion 5
      "propietario": _nuevoNombreController.text,
      "direccion_ficha": _nuevoDireccionController.text,
      "codsector_comercial": _selectedSectorComercial?['id'],
      // Seccion 6
      "tiporesponsable": _selectedTipoResponsablePredio,
      // Seccion 7
      "tipoconstruccion": _selectedTipoConstruccion,
      "tipopredio": _selectedTipoPredio,
      "tipomatconstruccion": _selectedMaterialConstruccion,
      "tiposervicio": _selectedTipoServicio,
      "nropisos": _numeroPisosController.text,
      "habitada": _selectedOpcionHabitada == 1
          ? true
          : _selectedOpcionHabitada == 2
              ? false
              : null,
      "agua_comite": _selectedOpcionAguaComite == 1
          ? true
          : _selectedOpcionAguaComite == 2
              ? false
              : null,
      "nro_personas": _numeroPersonasController.text,
      "nro_familias": _numeroFamiliasController.text == '' ? null : _numeroFamiliasController.text,
      "piscina": _selectedOpcionPiscina,
      "conpozo": _selectedOpcionPozoArtesiano,
      "tarifas": arrayTarifas,
      // Seccion 8
      "caracteconexionagua": _selectedCaracteristicaConexionAgua,
      "diametrosagua": _selectedDiametroConexionAgua,
      "tipomaterialagua": _selectedMaterialConexionAgua,
      "situacionconexiongua": _selectedSituacionConexionAgua,
      "fugasyatoros": _selectedOpcionFugaAgua,
      // Seccion 9
      "locacajaagua": _selectedUbicacionCajaAgua,
      "profundidad": _profundidadCajaAguaController.text,
      "tipocajaagua": _selectedMaterialCajaAgua,
      "estadocajaagua": _selectedEstadoCajaAgua,
      // Seccion 10
      "tipotapaagua": _selectedMaterialMarcoTapaAgua,
      "estadotapaagua": _selectedEstadoMarcoTapaAgua,
      // Seccion 11
      "nromedidor": _nroMedidorController.text,
      "lecturaultima": int.tryParse(_lecturaMedidorController.text),
      "marcamedidor": _selectedMarcaMedidor,
      "diametrosmedidor": _selectedDiametroConexionMedidor,
      "estadomedidor": _selectedEstadoMedidor,
      "codaccesorio": _selectedAccesorioMedidor,
      "estado_codaccesorio": _selectedEstadoAccesorioMedidor,
      // Seccion 12
      "codcaracteconexiondesague": _selectedCaracteristicaConexionDesague,
      "diametrosdesague": _selectedDiametroConexionDesague,
      "tipomaterialdesague": _selectedMaterialConexionDesague,
      "codsituacionconexiondesague": _selectedSituacionConexionDesague,
      // Seccion 13
      "locacajadesague": _selectedUbicacionCajaDesague,
      "tipocajadesague": _selectedMaterialCajaDesague,
      "estadocajadesague": _selectedEstadoCajaDesague,
      // Seccion 14
      "tipotapadesague": _selectedMaterialTapaCajaDesague,
      "estadotapadesague": _selectedEstadoTapaCajaDesague,
      // Seccion 15
      "tipoabastecimiento": _selectedAbastecimientoComplementario,
      "codjardinhuerto": _selectedJardinHuertoComplementario,
      "codsaneamiento": _selectedSaneamientoComplementario,
      "horasabastecimiento": int.tryParse(_horasAbastecimientoController.text),
      "tipoalmacenaje": _selectedAlmacenamientoComplementario,
      "tipovereda": _selectedTipoVeredaComplementario,
      "pavimentoagua": _selectedPavimentoComplementario,
      // Seccion 16
      "frontera": _fronteraPredioController.text,
      "frontera2": _frontera2PredioController.text,
      "areapredio": _areaPredioController.text,
      "areaconstruida": _areaConstruidaController.text,
      // Seccion 17
      "cotacnxagua": _cotaCnxApController.text,
      "cotacnxdesague": _cotaCnxAlcController.text,
      "longitud_agua": _longitudAguaController.text,
      "latitud_agua": _latitudAguaController.text,
      "longitud_desague": _longitudDesagueController.text,
      "latitud_desague": _latitudDesagueController.text,
      // Seccion 18
      "zonapresion": _zonasPresionController.text,
      // Seccion 21
      "observacionficha": _observacionesController.text == '' ? null : _observacionesController.text,
      // Seccion 22
      "fechaencuesta": _fechaEncuestaController.text,
      // Seccion 23
      "empadronador": _empadronadorId,
      // Seccion 24
      "supervisor": _selectedSupervisor?['id'],
      // Seccion 25
      "digitador": _selectedDigitador?['id'],
      // Seccion 26
      "fechadigitacion": _fechaDigitacionController.text,
    };
    await CacheCadastro.save(data);
  }

  @override
  void initState() {
    super.initState();
    _selectedSupervisor = {"id": "", "dni": "", "name": "Seleccionar", "position": ""};
    _selectedDigitador = {"id": "", "dni": "", "name": "Seleccionar", "position": ""};
    _loadLocalUsers();
    _loadEmpadronadorData();
    _loadData();
    _filteredSectores = [];
    _filteredManzanas = [];

    // Escucha cambios en todos los controladores
    for (var controller in [
      // Seccion 3
      _nroInscripcionController,
      _codigoCatastralController,
      _nombreController,
      _direccionController,
      _sectorComercialController,
      // Seccion 4
      _provinciaController,
      _distritoController,
      _zaController,
      _mzController,
      _loteController,
      _conexionController,
      // Seccion 5
      _nuevoNombreController,
      _nuevoDireccionController,
      // Seccion 7
      _numeroPisosController,
      _numeroPersonasController,
      _numeroFamiliasController,
      // Seccion 9
      _profundidadCajaAguaController,
      // Seccion 11
      _nroMedidorController,
      _lecturaMedidorController,
      // Seccion 15
      _horasAbastecimientoController,
      // Seccion 16
      _fronteraPredioController,
      _frontera2PredioController,
      _areaPredioController,
      _areaConstruidaController,
      // Seccion 17
      _cotaCnxApController,
      _cotaCnxAlcController,
      // Seccion 18
      _zonasPresionController,
      // Seccion 19
      _zonaAbastecimientoController,
      // Seccion 21
      _observacionesController,
    ]) {
      controller.addListener(() {
        if (_isFillingFromApi) return;
        _saveCache();
        setState(() {});
      });
    }

    // Inicializa las unidades de uso en falso y sin actividad
    for (var uso in _unidadesUso) {
      _usosSeleccionados[uso['id']] = false;
      _actividadesSeleccionadas[uso['id']] = null;
    }
  }

  @override
  void dispose() {
    for (var controller in [
      // Seccion 3
      _nroInscripcionController,
      _codigoCatastralController,
      _nombreController,
      _direccionController,
      _sectorComercialController,
      // Seccion 4
      _provinciaController,
      _distritoController,
      _zaController,
      _mzController,
      _loteController,
      _conexionController,
      // Seccion 5
      _nuevoNombreController,
      _nuevoDireccionController,
      // Seccion 7
      _numeroPisosController,
      _numeroPersonasController,
      _numeroFamiliasController,
      // Seccion 9
      _profundidadCajaAguaController,
      // Seccion 11
      _nroMedidorController,
      _lecturaMedidorController,
      // Seccion 15
      _horasAbastecimientoController,
      // Seccion 16
      _fronteraPredioController,
      _frontera2PredioController,
      _areaPredioController,
      _areaConstruidaController,
      // Seccion 17
      _cotaCnxApController,
      _cotaCnxAlcController,
      // Seccion 18
      _zonasPresionController,
      // Seccion 19
      _zonaAbastecimientoController,
      // Seccion 21
      _observacionesController,
      // Seccion 22
      _fechaEncuestaController,
      // Seccion 26
      _fechaDigitacionController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSaveCadastral() async {
    if ((_selectedSucursal == null || _selectedSucursal?['id'] == '') ||
        (_selectedSector == null || _selectedSector?['id'] == '') ||
        (_selectedManzana == null || _selectedManzana?['id'] == '') ||
        _selectedtipoUsuario == null ||
        (_nroInscripcionController.text.isEmpty && nuevoCliente == false) ||
        _zaController.text == '' ||
        _loteController.text == '' ||
        _conexionController.text == '' ||
        (nuevoCliente == true && _nuevoNombreController.text.isEmpty) ||
        (nuevoCliente == true && _nuevoDireccionController.text.isEmpty) ||
        _selectedTipoResponsablePredio == null ||
        _selectedTipoConstruccion == null ||
        _selectedMaterialConstruccion == null ||
        _numeroPisosController.text == '' ||
        _selectedOpcionHabitada == null ||
        _selectedOpcionAguaComite == null ||
        _numeroPersonasController.text == '' ||
        _selectedOpcionPiscina == null ||
        _selectedOpcionPozoArtesiano == null ||
        arrayTarifas.isEmpty ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedCaracteristicaConexionAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedDiametroConexionAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMaterialConexionAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedSituacionConexionAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedOpcionFugaAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedUbicacionCajaAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _profundidadCajaAguaController.text.isEmpty) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMaterialCajaAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoCajaAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMaterialMarcoTapaAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoMarcoTapaAgua == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMarcaMedidor == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedDiametroConexionMedidor == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoMedidor == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedAccesorioMedidor == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoAccesorioMedidor == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedCaracteristicaConexionDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedDiametroConexionDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedMaterialConexionDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedSituacionConexionDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedUbicacionCajaDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedMaterialCajaDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedEstadoCajaDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedMaterialTapaCajaDesague == null) ||
        ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedEstadoTapaCajaDesague == null) ||
        _horasAbastecimientoController.text.isEmpty ||
        _selectedAlmacenamientoComplementario == null ||
        _fronteraPredioController.text.isEmpty ||
        _frontera2PredioController.text.isEmpty ||
        _cotaCnxApController.text.isEmpty ||
        _cotaCnxAlcController.text.isEmpty ||
        _longitudAguaController.text.isEmpty ||
        _latitudAguaController.text.isEmpty ||
        _longitudDesagueController.text.isEmpty ||
        _latitudDesagueController.text.isEmpty ||
        _zonaAbastecimientoController.text.isEmpty ||
        _fechaEncuestaController.text.isEmpty ||
        _empadronadorController.text.isEmpty ||
        _fechaDigitacionController.text.isEmpty) {
      snackBar(context, 'Solucione los errores en el formulario', type: SnackBarType.destructive);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // === FIN: VALIDACIÓN DE DUPLICADOS ===
    final String? sucursalId = _selectedSucursal?['id'];
    final String nroInscripcion = _nroInscripcionController.text.trim();
    // 🔑 Cambio 1: Mantener currentLocalId como String
    final String? currentLocalId = widget.localId; // ID del registro actual (null si es nuevo)

    if (nroInscripcion.isNotEmpty && sucursalId != null && sucursalId.isNotEmpty) {
      List<Map<String, dynamic>> allCadastrals = [];
      // Asumo que _localStorage.loadAllCadastrals() carga registros locales que tienen un campo 'localId'
      allCadastrals = await _localStorage.loadAllCadastrals();

      final bool existeDuplicado = allCadastrals.any((catastro) {
        // 🔑 Cambio 2: Leer catastroLocalId como String
        final String? catastroLocalId = catastro['localId']?.toString(); // ID del registro local en la lista

        final String? sucursalGuardada = catastro['sucursal']?.toString();
        final String? inscripcionGuardada = catastro['nroinscripcion']?.toString().trim();

        // 1. Verificar si los datos (sucursal e inscripción) coinciden
        final bool dataCoincide = sucursalGuardada == sucursalId && inscripcionGuardada == nroInscripcion;

        // 2. Si estamos en modo ACTUALIZACIÓN, ignorar el propio registro
        if (currentLocalId != null) {
          // Si los datos coinciden Y el ID es el mismo (comparación de Strings) -> NO es duplicado
          if (dataCoincide && catastroLocalId == currentLocalId) {
            return false;
          }
        }

        // 3. Si los datos coinciden y no es el registro actual (o estamos creando uno nuevo) -> ES DUPLICADO
        return dataCoincide;
      });

      setState(() {
        _isLoading = false;
      });

      if (existeDuplicado) {
        if (mounted) {
          snackBar(context, 'Ya existe un registro con la misma Sucursal y Número de Inscripción.', type: SnackBarType.destructive);
        }
        return; // Detiene la ejecución si hay duplicado
      }
    }
    // === FIN: VALIDACIÓN DE DUPLICADOS ===

    final data = {
      // Datos principales
      "sucursal": _selectedSucursal?['id'],
      "sector": _selectedSector?['id'].toInt(),
      "manzanas": _selectedManzana?['id'],
      "nuevo_cliente": nuevoCliente == true ? 1 : 0,
      // Seccion 2
      "tipousuario": _selectedtipoUsuario,
      // Seccion 3
      "nroinscripcion": (nuevoCliente == true) ? null : _nroInscripcionController.text,
      "codigo_cadastral": _codigoCatastralController.text,
      "nombre": _nombreController.text,
      "direccion": _direccionController.text,
      "sectorcomercial": _sectorComercialController.text,
      // Seccion 4
      "lote": _loteController.text,
      "sublote": _conexionController.text,
      // Seccion 5
      "propietario": (nuevoCliente == true) ? _nuevoNombreController.text : null,
      "direccion_ficha": (nuevoCliente == true) ? _nuevoDireccionController.text : null,
      "codsector_comercial": _selectedSectorComercial?['id'],
      // Seccion 6
      "tiporesponsable": _selectedTipoResponsablePredio,
      // Seccion 7
      "tipoconstruccion": _selectedTipoConstruccion,
      "tipopredio": _selectedTipoPredio,
      "tipomatconstruccion": _selectedMaterialConstruccion,
      "tiposervicio": _selectedTipoServicio,
      "nropisos": _numeroPisosController.text,
      "habitada": _selectedOpcionHabitada == 1
          ? true
          : _selectedOpcionHabitada == 2
              ? false
              : null,
      "agua_comite": _selectedOpcionAguaComite == 1
          ? true
          : _selectedOpcionAguaComite == 2
              ? false
              : null,
      "nro_personas": _numeroPersonasController.text,
      "nro_familias": _numeroFamiliasController.text == '' ? null : _numeroFamiliasController.text,
      "piscina": _selectedOpcionPiscina,
      "conpozo": _selectedOpcionPozoArtesiano,
      "tarifas": arrayTarifas,
      // Seccion 8
      "caracteconexionagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedCaracteristicaConexionAgua : null,
      "diametrosagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedDiametroConexionAgua : null,
      "tipomaterialagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedMaterialConexionAgua : null,
      "situacionconexiongua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedSituacionConexionAgua : null,
      "fugasyatoros": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedOpcionFugaAgua : null,
      // Seccion 9
      "locacajaagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedUbicacionCajaAgua : null,
      "profundidad": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _profundidadCajaAguaController.text : null,
      "tipocajaagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedMaterialCajaAgua : null,
      "estadocajaagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedEstadoCajaAgua : null,
      // Seccion 10
      "tipotapaagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedMaterialMarcoTapaAgua : null,
      "estadotapaagua": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedEstadoMarcoTapaAgua : null,
      // Seccion 11
      "nromedidor": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _nroMedidorController.text : null,
      "lecturaultima": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? int.tryParse(_lecturaMedidorController.text) : null,
      "marcamedidor": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedMarcaMedidor : null,
      "diametrosmedidor": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedDiametroConexionMedidor : null,
      "estadomedidor": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedEstadoMedidor : null,
      "codaccesorio": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedAccesorioMedidor : null,
      "estado_codaccesorio": (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ? _selectedEstadoAccesorioMedidor : null,
      // Seccion 12
      "codcaracteconexiondesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedCaracteristicaConexionDesague : null,
      "diametrosdesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedDiametroConexionDesague : null,
      "tipomaterialdesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedMaterialConexionDesague : null,
      "codsituacionconexiondesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedSituacionConexionDesague : null,
      // Seccion 13
      "locacajadesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedUbicacionCajaDesague : null,
      "tipocajadesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedMaterialCajaDesague : null,
      "estadocajadesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedEstadoCajaDesague : null,
      // Seccion 14
      "tipotapadesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedMaterialTapaCajaDesague : null,
      "estadotapadesague": (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ? _selectedEstadoTapaCajaDesague : null,
      // Seccion 15
      "tipoabastecimiento": _selectedAbastecimientoComplementario,
      "codjardinhuerto": _selectedJardinHuertoComplementario,
      "codsaneamiento": _selectedSaneamientoComplementario,
      "horasabastecimiento": int.tryParse(_horasAbastecimientoController.text),
      "tipoalmacenaje": _selectedAlmacenamientoComplementario,
      "tipovereda": _selectedTipoVeredaComplementario,
      "pavimentoagua": _selectedPavimentoComplementario,
      // Seccion 16
      "frontera": _fronteraPredioController.text,
      "frontera2": _frontera2PredioController.text,
      "areapredio": _areaPredioController.text,
      "areaconstruida": _areaConstruidaController.text,
      // Seccion 17
      "cotacnxagua": _cotaCnxApController.text,
      "cotacnxdesague": _cotaCnxAlcController.text,
      "longitud_agua": _longitudAguaController.text,
      "latitud_agua": _latitudAguaController.text,
      "longitud_desague": _longitudDesagueController.text,
      "latitud_desague": _latitudDesagueController.text,
      // Seccion 18
      "zonapresion": _zonasPresionController.text,
      // Seccion 21
      "observacionficha": _observacionesController.text == '' ? null : _observacionesController.text,
      // Seccion 22
      "fechaencuesta": _fechaEncuestaController.text,
      // Seccion 23
      "empadronador": _empadronadorId,
      // Seccion 24
      "supervisor": (_selectedSupervisor?['id'] == "" || _selectedSupervisor?['id'] == null) ? '' : _selectedSupervisor!['id'],
      // Seccion 25
      "digitador": (_selectedDigitador?['id'] == "" || _selectedDigitador?['id'] == null) ? '' : _selectedDigitador!['id'],
      // Seccion 26
      "fechadigitacion": _fechaDigitacionController.text,
    };

    final connectivityResult = await Connectivity().checkConnectivity();
    final bool isOnline = connectivityResult != ConnectivityResult.none;
    String finalMessage = '';
    SnackBarType messageType = SnackBarType.success;

    if (isOnline) {
      try {
        // Intenta la llamada a la API
        final apiResponse = await useCadastralSave(cadastral: data);

        // Si la API responde bien, actualiza el map 'data'
        data['nroinscripcion'] = apiResponse['nroinscripcion'];
        data['nroficha'] = apiResponse['nroficha'];
        finalMessage = 'Catastro sincronizado con éxito.';
      } catch (e) {
        messageType = SnackBarType.warning;
        finalMessage = 'Fallo al sincronizar, revise su conexion a internet. ${e.toString().replaceFirst('Exception: ', '')}';
      }
    } else {
      messageType = SnackBarType.warning;
      finalMessage = 'Sin conexión.';
    }

    bool localSaveSuccess = false;
    try {
      await _storage.saveCadastral(data, widget.localId);
      finalMessage += ' Catastro guardado de forma local.';
      localSaveSuccess = true;
      if (widget.localId == null) {
        await CacheCadastro.clear();
      }
    } catch (e) {
      finalMessage += ' No se pudo guardar el catastro de forma local.';
      messageType = SnackBarType.warning;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (mounted) {
      snackBar(context, finalMessage, type: messageType, duration: const Duration(seconds: 6));
      if (localSaveSuccess) {
        Navigator.pop(context, true);
      }
    }
  }

  Widget _buildCoordFields({
    required String label,
    required TextEditingController lonController,
    required TextEditingController latController,
    required VoidCallback onPick,
    required ColorsExtension? appColors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: onPick,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined),
              SizedBox(width: 8),
              Text('Seleccionar punto'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: lonController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Longitud *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: latController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Latitud *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // Método para manejar la apertura de la pantalla de mapa
  void _openMapPicker(String fieldName, TextEditingController controllerLon, TextEditingController controllerLat) async {
    if (_selectedSucursal?['id'] == null || _selectedSucursal?['id'] == '') {
      if (mounted) {
        snackBar(context, 'Seleccione una sucursal para cargar el mapa.', type: SnackBarType.destructive);
      }
      return;
    }

    final String sucursalName = _selectedSucursal!['name'];
    final String initialCoords = "${controllerLon.text},${controllerLat.text}";

    // Abre la nueva pantalla y espera el resultado (Longitud,Latitud)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          sucursalName: sucursalName,
          initialCoordinates: initialCoords,
          fieldName: fieldName,
        ),
      ),
    );

    // Si se obtuvo un resultado (coordenada seleccionada), actualiza el campo de texto
    // if (result != null && result is String) {
    //   final parts = result.split(',');
    //   if (parts.length == 2) {
    //     controllerLon.text = parts[0];
    //     controllerLat.text = parts[1];
    //   }
    // }

    if (result != null && result is String) {
      final parts = result.split(',');
      if (parts.length == 2) {
        _isFillingFromApi = true;
        controllerLon.text = parts[0];
        controllerLat.text = parts[1];
        _saveCache();
        _isFillingFromApi = false;

        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<ColorsExtension>();
    final schemaColor = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha Catastral - EPS'),
      ),
      body: _isLoading || _isLoadingCache
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Busqueda ===
                    _sectionSearch(schemaColor, appColors),
                    // === Seccion Principal ===
                    _sectionMain(schemaColor, appColors),

                    // === 1. Numero de Ficha ===
                    TextFormField(
                      controller: _nroFichaController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Número de Ficha',
                      ),
                    ),

                    // === 2. Tipo de Usuario ===
                    _section2(schemaColor, appColors),

                    // === 3. Datos Generales del Usuario ===
                    _section3(schemaColor, appColors),

                    // === 4. Nuevo Código Catastral ===
                    _section4(schemaColor, appColors),

                    // === 5. Datos Generales del Usuario (Registrados/No Registrados) ===
                    _section5(schemaColor, appColors),

                    // === 6. Responsable del Predio ===
                    _section6(schemaColor, appColors),

                    // === 7. Datos del Inmueble ===
                    _section7(schemaColor, appColors),

                    // === Mostrar secciones según tipo de servicio ===
                    if (_selectedTipoServicio == 1 || _selectedTipoServicio == 2) ...[
                      // === 8. DATOS DE LA CONEXIÓN DE AGUA POTABLE ===
                      _section8(schemaColor, appColors),

                      // === 9. DATOS DE LA CAJA DE AGUA ===
                      _section9(schemaColor, appColors),

                      // === 10. DATOS DEL MARCO Y TAPA DE CAJA DE AGUA ===
                      _section10(schemaColor, appColors),

                      // === 11. DATOS DEL MEDIDOR ===
                      _section11(schemaColor, appColors),
                    ],

                    if (_selectedTipoServicio == 1 || _selectedTipoServicio == 3) ...[
                      // === 12. DATOS DE LA CONEXIÓN DE DESAGÜE ===
                      _section12(schemaColor, appColors),

                      // === 13. DATOS DE LA CAJA DE REGISTRO DE DESAGÜE ===
                      _section13(schemaColor, appColors),

                      // === 14. DATOS DE LA TAPA DE CAJA REGISTRADORA DE DESAGÜE ===
                      _section14(schemaColor, appColors),
                    ],

                    // === 15. DATOS COMPLEMENTARIOS ===
                    _section15(schemaColor, appColors),

                    // === 16. REFERENTE AL PREDIO ===
                    _section16(schemaColor, appColors),

                    // === 17. CROQUIS ===
                    _section17(schemaColor, appColors),

                    // === 18–26. DATOS FINALES ===
                    _sectionEnd(schemaColor, appColors),
                    const SizedBox(height: 32),
                    _nroFichaController.text == ''
                        ? Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _handleSaveCadastral,
                                  icon: const Icon(Icons.save, size: 20),
                                  label: const Text('Guardar Ficha'),
                                ),
                                if (_isLoading) const CircularProgressIndicator(),
                              ],
                            ),
                          )
                        : const SizedBox(height: 32),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionSearch(schemaColor, appColors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt_rounded, color: schemaColor.primary),
                const SizedBox(width: 8),
                Text(
                  'Búsqueda de Ficha',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: schemaColor.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // === SELECT SUCURSAL ===
            DropdownSearch<Map<String, dynamic>>(
              selectedItem: _selectedSucursal,
              items: _sucursales,
              itemAsString: (branch) => branch['name'],
              onChanged: (data) {
                _isFillingFromApi = true;
                setState(() {
                  _selectedSucursal = data;
                  _provinciaController.text = data?['codprovincia'] ?? '';
                  _distritoController.text = data?['coddistrito'] ?? '';
                  _longitudAguaController.text = '';
                  _latitudAguaController.text = '';
                  _longitudDesagueController.text = '';
                  _latitudDesagueController.text = '';

                  _selectedSector = {'id': '', 'sucursalId': '', 'name': 'Seleccionar'};
                  _selectedManzana = {"sucursalId": "", "sectorId": "", "id": "", "name": "Seleccionar"};
                  _selectedSectorComercial = {'sucursalId': '', 'id': '', 'name': 'Seleccionar'};

                  // Filtra sectores de la sucursal seleccionada
                  if (data != null && data['id'] != '') {
                    _filteredSectores = _sectores.where((s) => s['sucursalId'].toString() == data['id'].toString()).toList();
                    _filteredSectoresComerciales = _sectoresComerciales.where((s) => s['sucursalId'].toString() == data['id'].toString()).toList();
                  } else {
                    _filteredSectores = [];
                    _filteredSectoresComerciales = [];
                  }
                  _filteredManzanas = [];
                });
                _isFillingFromApi = false;
                _saveCache();
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Sucursal *',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Buscar sucursal...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _selectedSucursal == null || _selectedSucursal?['id'] == '' ? Text('Selecciona la sucursal', style: TextStyle(color: appColors?.destructiveBase)) : const SizedBox.shrink(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedFilterType == FilterType.recordCode ? appColors?.info : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedFilterType == FilterType.recordCode ? (appColors?.infoBase ?? Colors.blueAccent) : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: RadioListTile<FilterType>(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      value: FilterType.recordCode,
                      groupValue: _selectedFilterType,
                      title: const Text('Código de inscripción'),
                      onChanged: (value) => setState(() => _selectedFilterType = value),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _selectedFilterType == FilterType.meterCode ? appColors?.info : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedFilterType == FilterType.meterCode ? (appColors?.infoBase ?? Colors.blueAccent) : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    child: RadioListTile<FilterType>(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      value: FilterType.meterCode,
                      groupValue: _selectedFilterType,
                      title: const Text('Código de medidor'),
                      onChanged: (value) => setState(() => _selectedFilterType = value),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _selectedSucursal == null || _selectedSucursal?['id'] == '' ? const Text('Selecciona la sucursal', style: TextStyle(color: Color(0xFFEBB517))) : const SizedBox.shrink(),
            _selectedFilterType != FilterType.recordCode && _selectedFilterType != FilterType.meterCode
                ? const Text('Selecciona el tipo de filtro', style: TextStyle(color: Color(0xFFEBB517)))
                : const SizedBox.shrink(),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recordCodeController,
                    enabled: _selectedSucursal != null && _selectedSucursal?['id'] != '' && _selectedFilterType != null,
                    decoration: InputDecoration(
                      labelText: _selectedFilterType == FilterType.recordCode
                          ? 'Código de inscripción'
                          : _selectedFilterType == FilterType.meterCode
                              ? 'Código de medidor'
                              : '',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 41,
                  child: ElevatedButton(
                    onPressed: (_selectedSucursal != null && _selectedSucursal!['id'] != '' && _selectedFilterType != null && _recordCodeController.text.trim().isNotEmpty)
                        ? () async {
                            FocusScope.of(context).unfocus(); // Cierra teclado
                            setState(() => _isLoading = true);
                            _isFillingFromApi = true;

                            try {
                              final CadastralHeadView cadastral = await useCadastralHeadView(
                                _selectedSucursal!['id'].toString(),
                                _selectedFilterType == FilterType.recordCode ? _recordCodeController.text.trim() : null,
                                _selectedFilterType == FilterType.meterCode ? _recordCodeController.text.trim() : null,
                              );
                              // === Datos encontrados ===
                              setState(() {
                                if (cadastral.typeUser != 4) {
                                  _selectedtipoUsuario = cadastral.typeUser;
                                } else {
                                  _selectedtipoUsuario = null;
                                }
                                // === Seleccionar sector ===
                                _selectedSector = _sectores.firstWhere(
                                  (s) => s['id'].toString() == cadastral.sectorId.toString(),
                                  orElse: () => {'id': '', 'sucursalId': '', 'name': 'Seleccionar'},
                                );
                                // === Filtrar manzanas del sector y sucursal seleccionados ===
                                if (_selectedSector != null && _selectedSector!['id'] != '' && _selectedSucursal!['id'] != '') {
                                  _filteredManzanas = _manzanas
                                      .where(
                                        (m) => m['sucursalId'].toString() == _selectedSucursal!['id'].toString() && m['sectorId'].toString() == _selectedSector!['id'].toString(),
                                      )
                                      .toList();
                                } else {
                                  _filteredManzanas = [];
                                }
                                // === Seleccionar manzana ===
                                _selectedManzana = _filteredManzanas.firstWhere(
                                  (m) => m['id'].toString() == cadastral.manzanaId.toString(),
                                  orElse: () => {"sucursalId": "", "sectorId": "", "id": "", "name": "Seleccionar"},
                                );
                                // === Seleccionar sector comercial ===
                                _selectedSectorComercial = _sectoresComerciales.firstWhere(
                                  (s) => s['id'].toString() == cadastral.commercialSector,
                                  orElse: () => {'sucursalId': '', 'id': '', 'name': 'Seleccionar'},
                                );

                                _nroInscripcionController.text = cadastral.recordCode;
                                _codigoCatastralController.text = cadastral.cadastro;
                                _nombreController.text = cadastral.name;
                                _direccionController.text = cadastral.address;
                                _zaController.text = cadastral.sectorId.toString();
                                _mzController.text = cadastral.manzanaId;
                                _loteController.text = cadastral.batch.toString();
                                _nroMedidorController.text = cadastral.nromedidor ?? '';
                                nuevoCliente = false;
                                final String sectorId = _selectedSector?['id']?.toString() ?? '';
                                final String sectorName = _selectedSector?['name']?.toString() ?? '';
                                if (sectorId.isNotEmpty && sectorName.isNotEmpty) {
                                  _zonaAbastecimientoController.text = '$sectorId. $sectorName';
                                } else {
                                  _zonaAbastecimientoController.text = '';
                                }
                                final String sectorComercialId = _selectedSectorComercial?['id']?.toString() ?? '';
                                final String sectorComercialName = _selectedSectorComercial?['name']?.toString() ?? '';
                                if (sectorComercialId.isNotEmpty && sectorComercialName.isNotEmpty) {
                                  _sectorComercialController.text = '$sectorComercialId. $sectorComercialName';
                                  _nuevoSectorComercialController.text = '$sectorComercialId. $sectorComercialName';
                                } else {
                                  _sectorComercialController.text = '';
                                  _nuevoSectorComercialController.text = '';
                                }
                              });
                              if (mounted) {
                                snackBar(context, 'Datos cargados correctamente', type: SnackBarType.success);
                              }
                            } catch (e) {
                              setState(() {
                                // Limpiar campos que se llenan con la API
                                _selectedtipoUsuario = null;
                                _selectedSector = {'id': '', 'sucursalId': '', 'name': 'Seleccionar'};
                                _selectedManzana = {"sucursalId": "", "sectorId": "", "id": "", "name": "Seleccionar"};
                                _selectedSectorComercial = {'sucursalId': '', 'id': '', 'name': 'Seleccionar'};
                                _nroInscripcionController.clear();
                                _codigoCatastralController.clear();
                                _nombreController.clear();
                                _direccionController.clear();
                                _zaController.clear();
                                _mzController.clear();
                                _loteController.clear();
                                _conexionController.clear();
                                _zonaAbastecimientoController.clear();
                                _sectorComercialController.clear();
                                _nuevoSectorComercialController.clear();
                                nuevoCliente = false;
                              });
                              if (mounted) {
                                snackBar(context, e.toString().replaceFirst('Exception: ', ''), type: SnackBarType.destructive);
                              }
                            } finally {
                              setState(() => _isLoading = false);
                              _isFillingFromApi = false;
                              _saveCache();
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionMain(schemaColor, appColors) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: schemaColor.primary),
                const SizedBox(width: 8),
                Text(
                  'Datos del cliente',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: schemaColor.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // === Seleccion del sector ===
            DropdownSearch<Map<String, dynamic>>(
              selectedItem: _selectedSector,
              items: _filteredSectores,
              itemAsString: (sector) => sector['id'].toString().isEmpty ? sector['name'] : '${sector['id']}. ${sector['name']}',
              onChanged: (data) {
                _isFillingFromApi = true;
                setState(() {
                  _selectedSector = data;
                  _selectedManzana = {"sucursalId": "", "sectorId": "", "id": "", "name": "Seleccionar"};
                  _zaController.text = _selectedSector!['id'].toString();
                  final String sectorId = _selectedSector?['id']?.toString() ?? '';
                  final String sectorName = _selectedSector?['name']?.toString() ?? '';
                  if (sectorId.isNotEmpty && sectorName.isNotEmpty) {
                    _zonaAbastecimientoController.text = '$sectorId. $sectorName';
                  } else {
                    _zonaAbastecimientoController.text = '';
                  }

                  // Filtra manzanas según sucursal y sector seleccionados
                  if (data != null && data['id'] != '' && _selectedSucursal!['id'] != '') {
                    _filteredManzanas = _manzanas.where((m) => m['sucursalId'].toString() == _selectedSucursal!['id'].toString() && m['sectorId'].toString() == data['id'].toString()).toList();
                  } else {
                    _filteredManzanas = [];
                  }
                });
                _isFillingFromApi = false;
                _saveCache();
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Sector *',
                  prefixIcon: Icon(Icons.area_chart),
                ),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Buscar Sector...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _selectedSector == null || _selectedSector?['id'] == '' ? Text('Selecciona el sector', style: TextStyle(color: appColors?.destructiveBase)) : const SizedBox.shrink(),
            const SizedBox(height: 16),
            // === Seleccion de la manzana ===
            DropdownSearch(
              selectedItem: _selectedManzana,
              items: _filteredManzanas,
              itemAsString: (manzana) => manzana['id'].toString().isEmpty ? manzana['name'] : '${manzana['id']}. ${manzana['name']}',
              onChanged: (data) {
                _isFillingFromApi = true;
                setState(() {
                  _selectedManzana = data;
                  _mzController.text = data?['id'] ?? '';
                });
                _isFillingFromApi = false;
                _saveCache();
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Manzana *',
                  prefixIcon: Icon(Icons.crop_square_outlined),
                ),
              ),
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: 'Buscar Manzana...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _selectedManzana == null || _selectedManzana?['id'] == '' ? Text('Selecciona la manzana', style: TextStyle(color: appColors?.destructiveBase)) : const SizedBox.shrink(),
            // === Nuevo cliente ===
            const SizedBox(height: 4),
            CheckboxListTile(
              title: const Text('Nuevo cliente'),
              value: nuevoCliente,
              onChanged: (bool? value) {
                _isFillingFromApi = true;
                setState(() {
                  nuevoCliente = value ?? false;
                  _selectedSectorComercial = {'sucursalId': '', 'id': '', 'name': 'Seleccionar'};
                  _nroInscripcionController.clear();
                  _codigoCatastralController.clear();
                  _nombreController.clear();
                  _direccionController.clear();
                  _loteController.clear();
                  _conexionController.clear();
                  _sectorComercialController.clear();
                  _nuevoSectorComercialController.clear();
                  _recordCodeController.clear();
                  _selectedFilterType = null;
                  if (nuevoCliente == true) {
                    _selectedtipoUsuario = 3;
                  } else {
                    _selectedtipoUsuario = null;
                  }
                });
                _isFillingFromApi = false;
                _saveCache();
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section2(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Tipo de Usuario *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (_selectedtipoUsuario == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _tiposUsuario.map((tipo) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedtipoUsuario == tipo['id']) {
                            _selectedtipoUsuario = null;
                          } else {
                            _selectedtipoUsuario = tipo['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tipo['id'],
                            groupValue: _selectedtipoUsuario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tipo['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section3(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3. Datos Generales del Usuario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nroInscripcionController,
                  readOnly: nuevoCliente,
                  decoration: const InputDecoration(
                    labelText: 'N° Inscripción *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_nroInscripcionController.text.isEmpty && nuevoCliente == false)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codigoCatastralController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Código Catastral',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombreController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _direccionController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sectorComercialController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Sector comercial',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section4(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '4. Nuevo Código Catastral',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _provinciaController,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cod. Provincia *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_provinciaController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _distritoController,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cod. Distrito *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_distritoController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _zaController,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Za. *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_zaController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _mzController,
                  readOnly: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mz. *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_mzController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _loteController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Lote *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_loteController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _conexionController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(2),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Conexión *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_conexionController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section5(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '5. Datos Generales del Usuario (Registrados/No Registrados)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nuevoNombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (nuevoCliente == true && _nuevoNombreController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nuevoDireccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (nuevoCliente == true && _nuevoDireccionController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                // === Seleccion del sector Comercial ===
                DropdownSearch<Map<String, dynamic>>(
                  selectedItem: _selectedSectorComercial,
                  items: _filteredSectoresComerciales,
                  itemAsString: (sector) => sector['id'].toString().isEmpty ? sector['name'] : '${sector['id']}. ${sector['name']}',
                  onChanged: (data) {
                    _isFillingFromApi = true;
                    setState(() {
                      _selectedSectorComercial = data;
                      final String sectorComercialId = _selectedSectorComercial?['id']?.toString() ?? '';
                      final String sectorComercialName = _selectedSectorComercial?['name']?.toString() ?? '';
                      if (sectorComercialId.isNotEmpty && sectorComercialName.isNotEmpty) {
                        _nuevoSectorComercialController.text = '$sectorComercialId. $sectorComercialName';
                      } else {
                        _nuevoSectorComercialController.text = '';
                      }
                    });
                    _isFillingFromApi = false;
                    _saveCache();
                  },
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'Sector Comercial',
                      prefixIcon: Icon(Icons.attach_money_sharp),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        labelText: 'Buscar Sector Comercial...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section6(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '6. Responsable del Predio *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (_selectedTipoResponsablePredio == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _tiposResponsablePredio.map((resp) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTipoResponsablePredio == resp['id']) {
                            _selectedTipoResponsablePredio = null;
                          } else {
                            _selectedTipoResponsablePredio = resp['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: resp['id'],
                            groupValue: _selectedTipoResponsablePredio,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(resp['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section7(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7. Datos del Inmueble',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                // === Tipo de Construcción ===
                const Text(
                  'Tipo de Construcción *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_selectedTipoConstruccion == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _tiposConstruccion.map((tipo) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTipoConstruccion == tipo['id']) {
                            _selectedTipoConstruccion = null;
                          } else {
                            _selectedTipoConstruccion = tipo['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tipo['id'],
                            groupValue: _selectedTipoConstruccion,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tipo['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Tipo de Predio ===
                const Text(
                  'Tipo de Predio',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Column(
                  children: _tiposPredio.map((tipo) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTipoPredio == tipo['id']) {
                            _selectedTipoPredio = null;
                          } else {
                            _selectedTipoPredio = tipo['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tipo['id'],
                            groupValue: _selectedTipoPredio,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tipo['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Material de Construcción ===
                const Text(
                  'Material de Construcción *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_selectedMaterialConstruccion == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesConstruccion.map((tipo) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialConstruccion == tipo['id']) {
                            _selectedMaterialConstruccion = null;
                          } else {
                            _selectedMaterialConstruccion = tipo['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tipo['id'],
                            groupValue: _selectedMaterialConstruccion,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tipo['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Tipo de Servicio ===
                const Text(
                  'Tipo de Servicio',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Column(
                  children: _tiposServicio.map((tipo) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTipoServicio == tipo['id']) {
                            _selectedTipoServicio = null;
                          } else {
                            _selectedTipoServicio = tipo['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tipo['id'],
                            groupValue: _selectedTipoServicio,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tipo['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // === Número de Pisos ===
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numeroPisosController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Número de Pisos *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_numeroPisosController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                // === Habitada ===
                const SizedBox(height: 12),
                const Text(
                  'Habitada *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_selectedOpcionHabitada == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _opcionesHabitada.map((op) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedOpcionHabitada == op['id']) {
                            _selectedOpcionHabitada = null;
                          } else {
                            _selectedOpcionHabitada = op['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: op['id'],
                            groupValue: _selectedOpcionHabitada,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(op['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // === Agua de comité ===
                const SizedBox(height: 12),
                const Text(
                  'Agua de comité *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_selectedOpcionAguaComite == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _opcionesAguaComite.map((op) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedOpcionAguaComite == op['id']) {
                            _selectedOpcionAguaComite = null;
                          } else {
                            _selectedOpcionAguaComite = op['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: op['id'],
                            groupValue: _selectedOpcionAguaComite,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(op['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // === Número de Personas ===
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numeroPersonasController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Número de Personas *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_numeroPersonasController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                // === Número de Familias ===
                const SizedBox(height: 12),
                TextFormField(
                  controller: _numeroFamiliasController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Número de Familias',
                    border: OutlineInputBorder(),
                  ),
                ),
                // === Tiene Piscina ===
                const SizedBox(height: 12),
                const Text(
                  'Tiene Piscina *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_selectedOpcionPiscina == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _opcionesPiscina.map((op) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedOpcionPiscina == op['id']) {
                            _selectedOpcionPiscina = null;
                          } else {
                            _selectedOpcionPiscina = op['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: op['id'],
                            groupValue: _selectedOpcionPiscina,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(op['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // === Pozo Artesiano ===
                const SizedBox(height: 12),
                const Text(
                  'Pozo Artesiano *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_selectedOpcionPozoArtesiano == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _opcionesPozoArtesiano.map((op) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedOpcionPozoArtesiano == op['id']) {
                            _selectedOpcionPozoArtesiano = null;
                          } else {
                            _selectedOpcionPozoArtesiano = op['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: op['id'],
                            groupValue: _selectedOpcionPozoArtesiano,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(op['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // === Unidades de Uso ===
                const SizedBox(height: 12),
                const Text(
                  'Unidades de Uso *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if (_usosSeleccionados.values.where((v) => v).isEmpty && arrayTarifas.isEmpty)
                  Text(
                    'Como mínimo seleccione una opción.',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),

                // === Checkboxes + dropdowns ===
                ..._unidadesUso.map((und) {
                  final id = und['id'];
                  final seleccionado = _usosSeleccionados[id] ?? false;
                  final actividadSeleccionada = _actividadesSeleccionadas[id];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _usosSeleccionados[id] = !(_usosSeleccionados[id] ?? false);
                          });
                        },
                        child: Row(
                          children: [
                            Checkbox(
                              value: seleccionado,
                              onChanged: (val) {
                                setState(() {
                                  _usosSeleccionados[id] = val ?? false;
                                });
                              },
                            ),
                            Text(und['name']),
                          ],
                        ),
                      ),
                      if (seleccionado) ...[
                        DropdownSearch<Map<String, dynamic>>(
                          items: [
                            const {'id': null, 'name': 'Seleccionar'},
                            ..._opcionesActividades,
                          ],
                          itemAsString: (item) => item['name'],
                          selectedItem: _opcionesActividades.firstWhere(
                            (e) => e['id'] == actividadSeleccionada,
                            orElse: () => {'id': null, 'name': 'Seleccionar'},
                          ),
                          onChanged: (value) {
                            final idActividad = value?['id'];
                            if (idActividad != null) {
                              _agregarTarifa(id, idActividad);
                            }
                            _saveCache();
                          },
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                labelText: 'Buscar Actividad...',
                                prefixIcon: Icon(Icons.search),
                              ),
                            ),
                          ),
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: InputDecoration(
                              labelText: 'Seleccione tipo de negocio (${und['name']})',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        if (actividadSeleccionada == null)
                          Text(
                            'Este campo es obligatorio',
                            style: TextStyle(color: appColors?.destructiveBase),
                          ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  );
                }),

                const SizedBox(height: 16),

                // === Tabla de tarifas agregadas ===
                if (arrayTarifas.isNotEmpty) ...[
                  const Text(
                    'Tarifas seleccionadas:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Table(
                    border: TableBorder.all(color: Colors.grey),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(3),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      // Encabezado
                      TableRow(
                        decoration: BoxDecoration(color: schemaColor.primary),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Und. de Uso', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('Actividad', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(''),
                          ),
                        ],
                      ),
                      // Filas dinámicas
                      ...arrayTarifas.asMap().entries.map((entry) {
                        final index = entry.key;
                        final tarifa = entry.value;

                        final unidadUso = _unidadesUso.firstWhere((u) => u['id'] == tarifa['idunidaduso'], orElse: () => {'name': 'Desconocido'})['name'] ?? 'Desconocido';
                        final actividad = _opcionesActividades.firstWhere((a) => a['id'] == tarifa['idactividad'], orElse: () => {'name': 'Desconocida'})['name'] ?? 'Desconocida';

                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(unidadUso),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(actividad),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: IconButton(
                                  icon: Icon(Icons.delete, color: appColors?.destructiveBase),
                                  onPressed: () => {
                                        _eliminarTarifa(index),
                                        _saveCache(),
                                      }),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section8(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '8. Datos de la Conexión de Agua Potable',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                // === Características de la Conexión ===
                const Text(
                  'Características de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedCaracteristicaConexionAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _caracteristicasConexionAgua.map((carac) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedCaracteristicaConexionAgua == carac['id']) {
                            _selectedCaracteristicaConexionAgua = null;
                          } else {
                            _selectedCaracteristicaConexionAgua = carac['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: carac['id'],
                            groupValue: _selectedCaracteristicaConexionAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(carac['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Diámetro de la Conexión ===
                const Text(
                  'Diámetro de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedDiametroConexionAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _diametrosConexionAgua.map((dia) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedDiametroConexionAgua == dia['id']) {
                            _selectedDiametroConexionAgua = null;
                          } else {
                            _selectedDiametroConexionAgua = dia['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: dia['id'],
                            groupValue: _selectedDiametroConexionAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(dia['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Material de la Conexión ===
                const Text(
                  'Material de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMaterialConexionAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesConexionAgua.map((mat) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialConexionAgua == mat['id']) {
                            _selectedMaterialConexionAgua = null;
                          } else {
                            _selectedMaterialConexionAgua = mat['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mat['id'],
                            groupValue: _selectedMaterialConexionAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mat['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Situación de la Conexión ===
                const Text(
                  'Situación de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedSituacionConexionAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _situacionesConexionAgua.map((carac) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedSituacionConexionAgua == carac['id']) {
                            _selectedSituacionConexionAgua = null;
                          } else {
                            _selectedSituacionConexionAgua = carac['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: carac['id'],
                            groupValue: _selectedSituacionConexionAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(carac['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Fugas ===
                const Text(
                  'Fugas *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedOpcionFugaAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _opcionesFugaAgua.map((carac) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedOpcionFugaAgua == carac['id']) {
                            _selectedOpcionFugaAgua = null;
                          } else {
                            _selectedOpcionFugaAgua = carac['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: carac['id'],
                            groupValue: _selectedOpcionFugaAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(carac['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section9(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '9. Datos de la Caja de Agua',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                // === Ubicación de la Caja ===
                const Text(
                  'Ubicación de la Caja *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedUbicacionCajaAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _ubicacionesCajaAgua.map((ubi) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedUbicacionCajaAgua == ubi['id']) {
                            _selectedUbicacionCajaAgua = null;
                          } else {
                            _selectedUbicacionCajaAgua = ubi['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: ubi['id'],
                            groupValue: _selectedUbicacionCajaAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(ubi['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Profundidad ===
                TextFormField(
                  controller: _profundidadCajaAguaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Profundidad (m) *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _profundidadCajaAguaController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 12),
                // === Material de la Caja ===
                const Text(
                  'Material de la Caja *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMaterialCajaAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesCajaAgua.map((mat) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialCajaAgua == mat['id']) {
                            _selectedMaterialCajaAgua = null;
                          } else {
                            _selectedMaterialCajaAgua = mat['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mat['id'],
                            groupValue: _selectedMaterialCajaAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mat['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                // === Estado de la Caja ===
                const Text(
                  'Estado de la Caja *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoCajaAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _estadosCajaAgua.map((est) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEstadoCajaAgua == est['id']) {
                            _selectedEstadoCajaAgua = null;
                          } else {
                            _selectedEstadoCajaAgua = est['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: est['id'],
                            groupValue: _selectedEstadoCajaAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(est['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section10(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '10. Datos del Marco y Tapa de Caja de Agua',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Material del Marco y Tapa *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMaterialMarcoTapaAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesMarcoTapaAgua.map((ubi) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialMarcoTapaAgua == ubi['id']) {
                            _selectedMaterialMarcoTapaAgua = null;
                          } else {
                            _selectedMaterialMarcoTapaAgua = ubi['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: ubi['id'],
                            groupValue: _selectedMaterialMarcoTapaAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(ubi['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estado del Marco y Tapa *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoMarcoTapaAgua == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _estadosMarcoTapaAgua.map((ubi) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEstadoMarcoTapaAgua == ubi['id']) {
                            _selectedEstadoMarcoTapaAgua = null;
                          } else {
                            _selectedEstadoMarcoTapaAgua = ubi['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: ubi['id'],
                            groupValue: _selectedEstadoMarcoTapaAgua,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(ubi['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section11(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '11. Datos del Medidor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nroMedidorController,
                  decoration: const InputDecoration(
                    labelText: 'Número del Medidor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                // Lectura
                TextFormField(
                  controller: _lecturaMedidorController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Lectura',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Marca del medidor *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedMarcaMedidor == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _marcasMedidor.map((mar) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMarcaMedidor == mar['id']) {
                            _selectedMarcaMedidor = null;
                          } else {
                            _selectedMarcaMedidor = mar['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mar['id'],
                            groupValue: _selectedMarcaMedidor,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mar['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Diámetro de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedDiametroConexionMedidor == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _diametrosConexionMedidor.map((dia) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedDiametroConexionMedidor == dia['id']) {
                            _selectedDiametroConexionMedidor = null;
                          } else {
                            _selectedDiametroConexionMedidor = dia['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: dia['id'],
                            groupValue: _selectedDiametroConexionMedidor,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(dia['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estado del Medidor *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoMedidor == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _estadosMedidor.map((est) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEstadoMedidor == est['id']) {
                            _selectedEstadoMedidor = null;
                          } else {
                            _selectedEstadoMedidor = est['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: est['id'],
                            groupValue: _selectedEstadoMedidor,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(est['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                // === Datos de los Accesorios ===
                const Text(
                  'Accesorios *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedAccesorioMedidor == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _accesoriosMedidor.map((acc) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedAccesorioMedidor == acc['id']) {
                            _selectedAccesorioMedidor = null;
                          } else {
                            _selectedAccesorioMedidor = acc['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: acc['id'],
                            groupValue: _selectedAccesorioMedidor,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(acc['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Estado del accesorio *',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 2) && _selectedEstadoAccesorioMedidor == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _estadosAccesorioMedidor.map((mar) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEstadoAccesorioMedidor == mar['id']) {
                            _selectedEstadoAccesorioMedidor = null;
                          } else {
                            _selectedEstadoAccesorioMedidor = mar['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mar['id'],
                            groupValue: _selectedEstadoAccesorioMedidor,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mar['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section12(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '12. Datos de la Conexión de Desagüe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Características de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedCaracteristicaConexionDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _caracteristicasConexionDesague.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedCaracteristicaConexionDesague == tip['id']) {
                            _selectedCaracteristicaConexionDesague = null;
                          } else {
                            _selectedCaracteristicaConexionDesague = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedCaracteristicaConexionDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Diámetro de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedDiametroConexionDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _diametrosConexionDesague.map((mar) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedDiametroConexionDesague == mar['id']) {
                            _selectedDiametroConexionDesague = null;
                          } else {
                            _selectedDiametroConexionDesague = mar['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mar['id'],
                            groupValue: _selectedDiametroConexionDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mar['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Material de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedMaterialConexionDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesConexionDesague.map((mar) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialConexionDesague == mar['id']) {
                            _selectedMaterialConexionDesague = null;
                          } else {
                            _selectedMaterialConexionDesague = mar['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mar['id'],
                            groupValue: _selectedMaterialConexionDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mar['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Situación de la Conexión *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedSituacionConexionDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _situacionesConexionDesague.map((mar) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedSituacionConexionDesague == mar['id']) {
                            _selectedSituacionConexionDesague = null;
                          } else {
                            _selectedSituacionConexionDesague = mar['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: mar['id'],
                            groupValue: _selectedSituacionConexionDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(mar['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section13(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '13. Datos de la Caja de Registro de Desagüe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ubicación de la Caja *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedUbicacionCajaDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _ubicacionesCajaDesague.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedUbicacionCajaDesague == tip['id']) {
                            _selectedUbicacionCajaDesague = null;
                          } else {
                            _selectedUbicacionCajaDesague = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedUbicacionCajaDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Material de la Caja *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedMaterialCajaDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesCajaDesague.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialCajaDesague == tip['id']) {
                            _selectedMaterialCajaDesague = null;
                          } else {
                            _selectedMaterialCajaDesague = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedMaterialCajaDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estado de la Caja *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedEstadoCajaDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _estadosCajaDesague.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEstadoCajaDesague == tip['id']) {
                            _selectedEstadoCajaDesague = null;
                          } else {
                            _selectedEstadoCajaDesague = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedEstadoCajaDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section14(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '14. Datos de la Tapa de Caja Registradora de Desagüe',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Material de la Tapa *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedMaterialTapaCajaDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _materialesTapaCajaDesague.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedMaterialTapaCajaDesague == tip['id']) {
                            _selectedMaterialTapaCajaDesague = null;
                          } else {
                            _selectedMaterialTapaCajaDesague = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedMaterialTapaCajaDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Estado de la Tapa *',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((_selectedTipoServicio == 1 || _selectedTipoServicio == 3) && _selectedEstadoTapaCajaDesague == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _estadosTapaCajaDesague.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEstadoTapaCajaDesague == tip['id']) {
                            _selectedEstadoTapaCajaDesague = null;
                          } else {
                            _selectedEstadoTapaCajaDesague = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedEstadoTapaCajaDesague,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section15(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '15. Datos Complementarios',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text('Abastecimiento', style: TextStyle(fontWeight: FontWeight.w700)),
                Column(
                  children: _abastecimientosComplementario.map((abas) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedAbastecimientoComplementario == abas['id']) {
                            _selectedAbastecimientoComplementario = null;
                          } else {
                            _selectedAbastecimientoComplementario = abas['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: abas['id'],
                            groupValue: _selectedAbastecimientoComplementario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(abas['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('Jardín / Huerto', style: TextStyle(fontWeight: FontWeight.w700)),
                Column(
                  children: _jardinHuertosComplementario.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedJardinHuertoComplementario == tip['id']) {
                            _selectedJardinHuertoComplementario = null;
                          } else {
                            _selectedJardinHuertoComplementario = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedJardinHuertoComplementario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('Saneamiento', style: TextStyle(fontWeight: FontWeight.w700)),
                Column(
                  children: _saneamientosComplementario.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedSaneamientoComplementario == tip['id']) {
                            _selectedSaneamientoComplementario = null;
                          } else {
                            _selectedSaneamientoComplementario = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedSaneamientoComplementario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _horasAbastecimientoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Horas de abastecimiento *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_horasAbastecimientoController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 8),
                const Text('Almacenamiento', style: TextStyle(fontWeight: FontWeight.w700)),
                if (_selectedAlmacenamientoComplementario == null)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 4),
                Column(
                  children: _almacenamientosComplementario.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedAlmacenamientoComplementario == tip['id']) {
                            _selectedAlmacenamientoComplementario = null;
                          } else {
                            _selectedAlmacenamientoComplementario = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedAlmacenamientoComplementario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('Tipo de Vereda', style: TextStyle(fontWeight: FontWeight.w700)),
                Column(
                  children: _tiposVeredaComplementario.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedTipoVeredaComplementario == tip['id']) {
                            _selectedTipoVeredaComplementario = null;
                          } else {
                            _selectedTipoVeredaComplementario = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedTipoVeredaComplementario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('Pavimento', style: TextStyle(fontWeight: FontWeight.w700)),
                Column(
                  children: _pavimentosComplementario.map((tip) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedPavimentoComplementario == tip['id']) {
                            _selectedPavimentoComplementario = null;
                          } else {
                            _selectedPavimentoComplementario = tip['id'];
                          }
                        });
                        _saveCache();
                      },
                      child: Row(
                        children: [
                          Radio<int>(
                            value: tip['id'],
                            groupValue: _selectedPavimentoComplementario,
                            fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                              if (states.contains(WidgetState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return Colors.grey;
                            }),
                            onChanged: null,
                          ),
                          Text(tip['name']),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section16(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '16. Referente al Predio',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fronteraPredioController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Frontera (m)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_fronteraPredioController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _frontera2PredioController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Frontera 2 (m)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_frontera2PredioController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaPredioController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Área del Predio (m²)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _areaConstruidaController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Área Construida (m²)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _section17(schemaColor, appColors) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '17. Croquis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cotaCnxApController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cota cnx.AP *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_cotaCnxApController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cotaCnxAlcController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Cota cnx. ALC *',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_cotaCnxAlcController.text.isEmpty)
                  Text(
                    'Este campo es obligatorio',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Coordenadas de agua *',
                  style: TextStyle(fontSize: 16),
                ),
                _buildCoordFields(
                  label: "Agua",
                  lonController: _longitudAguaController,
                  latController: _latitudAguaController,
                  onPick: () => _openMapPicker(
                    'agua',
                    _longitudAguaController,
                    _latitudAguaController,
                  ),
                  appColors: appColors,
                ),
                if (_longitudAguaController.text.isEmpty || _latitudAguaController.text.isEmpty)
                  Text(
                    'Campos obligatorios',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Coordenadas de desague *',
                  style: TextStyle(fontSize: 16),
                ),
                _buildCoordFields(
                  label: "Desagüe",
                  lonController: _longitudDesagueController,
                  latController: _latitudDesagueController,
                  onPick: () => _openMapPicker(
                    'desague',
                    _longitudDesagueController,
                    _latitudDesagueController,
                  ),
                  appColors: appColors,
                ),
                if (_longitudDesagueController.text.isEmpty || _latitudDesagueController.text.isEmpty)
                  Text(
                    'Campos obligatorios',
                    style: TextStyle(color: appColors?.destructiveBase),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionEnd(schemaColor, appColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === 18. ZONAS DE PRESIÓN ===
        const SizedBox(height: 24),
        TextFormField(
          controller: _zonasPresionController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          decoration: const InputDecoration(
            labelText: '18. Zona de Presión *',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // === 19. ZONA DE ABASTECIMIENTO ===
        TextFormField(
          controller: _zonaAbastecimientoController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: '19. Zona de Abastecimiento *',
            border: OutlineInputBorder(),
          ),
        ),
        if (_zonaAbastecimientoController.text.isEmpty)
          Text(
            'Este campo es obligatorio',
            style: TextStyle(color: appColors?.destructiveBase),
          ),
        const SizedBox(height: 16),
        // === 20. SECTOR COMERCIAL ===
        TextFormField(
          controller: _nuevoSectorComercialController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: '20. Sector Comercial',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        // === 21. OBSERVACIONES ===
        TextFormField(
          controller: _observacionesController,
          decoration: const InputDecoration(
            labelText: '21. Observaciones',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fechaEncuestaController,
          readOnly: true,
          onTap: _selectFechaEncuesta,
          decoration: const InputDecoration(
            labelText: '22. Fecha de Encuesta *',
            border: OutlineInputBorder(),
          ),
        ),
        if (_fechaEncuestaController.text.isEmpty)
          Text(
            'Este campo es obligatorio',
            style: TextStyle(color: appColors?.destructiveBase),
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _empadronadorController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: '23. Empadronador *',
            border: OutlineInputBorder(),
          ),
        ),
        if (_empadronadorController.text.isEmpty)
          Text(
            'Este campo es obligatorio',
            style: TextStyle(color: appColors?.destructiveBase),
          ),
        const SizedBox(height: 16),
        DropdownSearch<Map<String, dynamic>>(
          selectedItem: _selectedSupervisor,
          items: _supervisores,
          itemAsString: (sup) => sup['name'],
          onChanged: (data) {
            setState(() {
              _selectedSupervisor = data;
            });
            _saveCache();
          },
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: '24. V° B° Supervisor',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                labelText: 'Buscar Supervisor...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DropdownSearch<Map<String, dynamic>>(
          selectedItem: _selectedDigitador,
          items: _digitadores,
          itemAsString: (sup) => sup['name'],
          onChanged: (data) {
            setState(() {
              _selectedDigitador = data;
            });
            _saveCache();
          },
          dropdownDecoratorProps: const DropDownDecoratorProps(
            dropdownSearchDecoration: InputDecoration(
              labelText: '25. Digitado por',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          popupProps: const PopupProps.menu(
            showSearchBox: true,
            searchFieldProps: TextFieldProps(
              decoration: InputDecoration(
                labelText: 'Buscar Digitador...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fechaDigitacionController,
          readOnly: true,
          onTap: _selectFechaDigitacion,
          decoration: const InputDecoration(
            labelText: '26. Fecha de Digitación',
            border: OutlineInputBorder(),
          ),
        ),
        if (_fechaDigitacionController.text.isEmpty)
          Text(
            'Este campo es obligatorio',
            style: TextStyle(color: appColors?.destructiveBase),
          ),
      ],
    );
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  Future<void> _selectFechaEncuesta() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      _fechaEncuestaController.text = formatDate(picked);
      _saveCache();
    }
  }

  Future<void> _selectFechaDigitacion() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _fechaDigitacionController.text = formatDate(picked);
      _saveCache();
    }
  }
}
