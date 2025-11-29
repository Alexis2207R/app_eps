import 'package:app_eps/app/cadastral/data/lista_sucursales.dart';
import 'package:app_eps/app/cadastral/services/service_cadastral_local_image.dart';
import 'package:app_eps/app/cadastral/ui/ui_cadastral_form.dart';
import 'package:app_eps/app/cadastral/type/type_cadastral_list.dart';
import 'package:app_eps/app/cadastral/ui/ui_cadastral_image.dart';
import 'package:app_eps/config/constants.dart';
import 'package:app_eps/config/themes/colors_extension.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FilterType {
  final int id;
  final String name;
  const FilterType({required this.id, required this.name});
}

class UiCadastralList extends StatefulWidget {
  final Future<List<CadastralList>> cadastralsFuture;
  final List<Map<String, dynamic>> _sucursales = listaSucursales;

  final Function(int?) onFilterSelected;

  const UiCadastralList({
    super.key,
    required this.cadastralsFuture,
    required this.onFilterSelected,
  });

  @override
  State<UiCadastralList> createState() => _UiCadastralListState();
}

class _UiCadastralListState extends State<UiCadastralList> {
  static const List<FilterType> _cadastralTypesFuture = [
    FilterType(id: 0, name: 'Todos'),
    FilterType(id: 1, name: 'Sincronizados'),
    FilterType(id: 2, name: 'Pendientes'),
  ];

  int? _selectedTypeId;
  String _selectedSucursalId = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  List<CadastralList> _allCadastrals = [];
  List<CadastralList> _searchedCadastrals = [];
  List<CadastralList> _pagedCadastrals = [];
  int _currentPage = 0;
  final int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _selectedTypeId = _cadastralTypesFuture.first.id;
    _selectedSucursalId = widget._sucursales.first['id'] as String;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchText != _searchController.text) {
        setState(() {
          _searchText = _searchController.text;
          _currentPage = 0;
          _applySearchAndPagination();
        });
      }
    });
  }

  // 2. Lógica de Filtrado y Paginación
  void _applySearchAndPagination() {
    List<CadastralList> tempSearchedList = _allCadastrals.where((cadastral) {
      final query = _searchText.toLowerCase();

      // FILTRO POR SUCURSAL
      final String cadastralSucursalId = cadastral.sucursal.toString();
      final bool matchesSucursal = _selectedSucursalId.isEmpty || cadastralSucursalId == _selectedSucursalId;

      // FILTRO POR BÚSQUEDA
      final bool matchesSearch = (cadastral.propietario?.toLowerCase().contains(query) ?? false) ||
          (cadastral.nromedidor?.toLowerCase().contains(query) ?? false) ||
          (cadastral.direccionFicha?.toLowerCase().contains(query) ?? false) ||
          (cadastral.nroInscripcion?.toLowerCase().contains(query) ?? false);

      // COMBINACIÓN: Debe coincidir con la sucursal Y con la búsqueda
      return matchesSucursal && matchesSearch;
    }).toList();

    _searchedCadastrals = tempSearchedList;
    final int start = _currentPage * _rowsPerPage;
    final int end = (_currentPage + 1) * _rowsPerPage;

    setState(() {
      _pagedCadastrals = _searchedCadastrals.sublist(start, end > _searchedCadastrals.length ? _searchedCadastrals.length : end);
    });
  }

  void _nextPage() {
    final totalPages = (_allCadastrals.length / _rowsPerPage).ceil();
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
        _applySearchAndPagination();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        _applySearchAndPagination();
      });
    }
  }

  Future<void> _launchUrl(String sucursalId, String nroInscripcion) async {
    // Construye la URL completa de tu API PHP
    const String baseUrl = '$apiUrl/app/actualizacion/ficha_catastral.php';
    final Uri url = Uri.parse('$baseUrl?nroinscripcion=$nroInscripcion&codsuc=$sucursalId');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Manejo de errores si el navegador no se puede abrir
      throw Exception('No se pudo abrir la URL: $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<ColorsExtension>();
    final int totalCadastrals = _searchedCadastrals.length;
    final int totalPages = (totalCadastrals / _rowsPerPage).ceil();
    final int startItem = totalCadastrals == 0 ? 0 : (_currentPage * _rowsPerPage) + 1;
    final int endItem = startItem + _pagedCadastrals.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: _selectedSucursalId,
            decoration: const InputDecoration(
              labelText: 'Filtrar por Sucursal',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: widget._sucursales.map((sucursal) {
              return DropdownMenuItem<String>(
                value: sucursal['id'] as String,
                child: Text(sucursal['name'] as String),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedSucursalId = newValue;
                  _currentPage = 0;
                  _applySearchAndPagination();
                });
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              child: Row(
                children: _cadastralTypesFuture.map((type) {
                  final isSelected = (_selectedTypeId == null && type.id == -1) || _selectedTypeId == type.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(type.name),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTypeId = type.id;
                          });
                          widget.onFilterSelected(_selectedTypeId);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar por Propietario, Medidor o Inscripción',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<CadastralList>>(
            future: widget.cadastralsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Text('No hay catastros ${_selectedTypeId == 1 ? 'sincronizados' : _selectedTypeId == 2 ? 'pendientes' : 'registrados'}.'));
              } else {
                if (!listEquals(snapshot.data!, _allCadastrals)) {
                  _allCadastrals = snapshot.data!;
                  _currentPage = 0;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _applySearchAndPagination();
                  });
                }
                if (_searchedCadastrals.isEmpty && _searchText.isNotEmpty) {
                  return const Center(child: Text('No se encontraron resultados para la búsqueda.'));
                }

                final cadastrals = _pagedCadastrals;

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0, top: 0.0),
                  itemCount: cadastrals.length,
                  itemBuilder: (context, index) {
                    final cadastral = cadastrals[index];
                    final appColors = Theme.of(context).extension<ColorsExtension>();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UiCadastralForm(localId: cadastral.localId),
                              ),
                            );
                            if (result != null && result == true) {
                              widget.onFilterSelected(_selectedTypeId);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // 1. LEADING (Ícono)
                                Icon(
                                  Icons.house_siding,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 16.0), // Espacio entre leading y content

                                // 2. TITLE & SUBTITLE (Contenido central)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'N° INS: ${cadastral.nroInscripcion ?? 'Sin Inscripción'}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16.0),
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        'Sucursal: ${cadastral.sucursal}',
                                        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                                      ),
                                      Text(
                                        'Medidor: ${cadastral.nromedidor ?? 'N/A'}',
                                        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                                      ),
                                      Text(
                                        'Dirección: ${cadastral.direccionFicha ?? 'Sin dirección'}',
                                        style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                                      ),
                                      FutureBuilder<int>(
                                        future: cadastralImageService.countSynchronizedImages(cadastral.localId!),
                                        builder: (context, snapshot) {
                                          final count = snapshot.data ?? 0;
                                          return Row(
                                            children: [
                                              const Text(
                                                'Fotos Sinc.: ',
                                                style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                                              ),
                                              Text(
                                                '$count',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  color: count > 0 ? appColors?.successBase : appColors?.warningBase,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4.0),
                                                child: Icon(
                                                  Icons.photo,
                                                  size: 16,
                                                  color: count > 0 ? appColors?.successBase : appColors?.warningBase,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      Row(
                                        children: [
                                          const Text(
                                            'Estado: ',
                                            style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
                                          ),
                                          Icon(
                                            cadastral.synchronized ? Icons.check_circle_outline : Icons.sync,
                                            size: 16,
                                            color: cadastral.synchronized ? appColors?.successBase : appColors?.warningBase,
                                          ),
                                          Text(
                                            cadastral.synchronized ? ' Sincronizado' : ' Pendiente',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: cadastral.synchronized ? appColors?.successBase : appColors?.warningBase,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón de PDF
                                    Card(
                                      color: appColors?.destructive,
                                      margin: const EdgeInsets.all(0.0),
                                      child: IconButton(
                                        iconSize: 25,
                                        icon: Icon(
                                          Icons.picture_as_pdf,
                                          color: appColors?.destructiveBase,
                                        ),
                                        onPressed: () async {
                                          await _launchUrl(
                                            cadastral.sucursal,
                                            cadastral.nroInscripcion ?? 'N/A',
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 12.0),
                                    // Botón de IMAGEN
                                    cadastral.synchronized
                                        ? Card(
                                            color: appColors?.success,
                                            margin: const EdgeInsets.all(0.0),
                                            child: IconButton(
                                              iconSize: 16,
                                              icon: Icon(Icons.image_rounded, color: appColors?.successBase),
                                              onPressed: () async {
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => UiCadastralImage(
                                                      localId: cadastral.localId!,
                                                      nroInscripcion: cadastral.nroInscripcion ?? 'N/A',
                                                      sucursal: cadastral.sucursal,
                                                    ),
                                                  ),
                                                );
                                                if (mounted && result != null) {
                                                  setState(() {});
                                                }
                                              },
                                            ),
                                          )
                                        : Card(
                                            color: appColors?.warning,
                                            margin: const EdgeInsets.all(0.0),
                                            child: IconButton(
                                              iconSize: 16,
                                              icon: Icon(Icons.image_not_supported_sharp, color: appColors?.warningBase),
                                              onPressed: () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => UiCadastralImage(
                                                      localId: cadastral.localId!,
                                                      nroInscripcion: cadastral.nroInscripcion ?? 'N/A',
                                                      sucursal: cadastral.sucursal,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
        // --- CONTROL DE PAGINACIÓN ---
        Container(
          margin: const EdgeInsets.only(left: 18.0, right: 18.0, top: 4.0, bottom: 16.0),
          decoration: BoxDecoration(
            color: appColors?.info,
            border: Border.all(color: appColors?.infoBase ?? Colors.blue),
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Mostrando $startItem - $endItem de $totalCadastrals registros',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 24.0),
                    onPressed: _currentPage > 0 ? _previousPage : null,
                  ),
                  Text('${_currentPage + 1} / $totalPages',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      )),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 24.0),
                    onPressed: _currentPage < totalPages - 1 && totalPages > 0 ? _nextPage : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  if (identical(a, b)) return true;
  for (int index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}
