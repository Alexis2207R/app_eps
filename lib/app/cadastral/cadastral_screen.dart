import 'package:app_eps/app/cadastral/type/type_cadastral_list.dart';
import 'package:app_eps/app/cadastral/ui/ui_cadastral_form.dart';
import 'package:app_eps/app/cadastral/ui/ui_cadastral_list.dart';
import 'package:app_eps/app/cadastral/usecases/use_cadastral_list.dart';
import 'package:flutter/material.dart';

class CadastralScreen extends StatefulWidget {
  const CadastralScreen({super.key});

  @override
  State<CadastralScreen> createState() => _CadastralScreenState();
}

class _CadastralScreenState extends State<CadastralScreen> {
  late Future<List<CadastralList>> _cadastralsFuture;
  int? _selectedTypeId;

  @override
  void initState() {
    super.initState();
    _loadCadastrals();
  }

  void _loadCadastrals([int? typeId]) {
    setState(() {
      _selectedTypeId = typeId;
      _cadastralsFuture = useCadastralList(typeId: typeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UiCadastralForm()),
                );
                if (result != null && result == true) {
                  _loadCadastrals(_selectedTypeId);
                }
              },
              icon: const Icon(Icons.save, size: 20),
              label: const Text('Registrar'),
            ),
          ),
          Expanded(
            child: UiCadastralList(
              cadastralsFuture: _cadastralsFuture,
              onFilterSelected: _loadCadastrals,
            ),
          ),
        ],
      ),
    );
  }
}
