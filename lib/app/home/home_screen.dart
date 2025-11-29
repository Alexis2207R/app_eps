import 'package:app_eps/app/cadastral/type/type_cadastral_list.dart';
import 'package:app_eps/app/cadastral/usecases/use_cadastral_list.dart';
import 'package:app_eps/config/themes/colors_extension.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<CadastralList>> _cadastralsFuture;

  @override
  void initState() {
    super.initState();
    _loadCadastrals();
  }

  void _loadCadastrals() {
    setState(() {
      _cadastralsFuture = useCadastralList(typeId: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panel Principal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<CadastralList>>(
        future: _cadastralsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }

          final cadastrals = snapshot.data ?? [];
          final int totalFichas = cadastrals.length;
          final int fichasSincronizadas = cadastrals.where((c) => c.synchronized).length;
          final int fichasNoSincronizadas = totalFichas - fichasSincronizadas;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCountCard(
                  context,
                  title: 'Catastros totales',
                  count: totalFichas,
                  type: 'primary',
                ),
                const SizedBox(height: 16),
                _buildCountCard(
                  context,
                  title: 'Catastros sin sincronizar',
                  count: fichasNoSincronizadas,
                  type: 'warning',
                ),
                const SizedBox(height: 16),
                _buildCountCard(
                  context,
                  title: 'Catastros sincronizados',
                  count: fichasSincronizadas,
                  type: 'success',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountCard(
    BuildContext context, {
    required String title,
    required int count,
    required String type,
  }) {
    final appColors = Theme.of(context).extension<ColorsExtension>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: type == 'primary'
                    ? appColors?.infoBase
                    : type == 'warning'
                        ? appColors?.warningBase
                        : appColors?.successBase,
              ),
            ),
            Card(
              color: type == 'primary'
                  ? appColors?.info
                  : type == 'warning'
                      ? appColors?.warning
                      : appColors?.success,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: type == 'primary'
                        ? appColors?.infoBase
                        : type == 'warning'
                            ? appColors?.warningBase
                            : appColors?.successBase,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
