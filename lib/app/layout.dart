import 'package:app_eps/app/cadastral/cadastral_screen.dart';
import 'package:app_eps/app/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:app_eps/config/responsive/responsive_width.dart';

class Layout extends StatefulWidget {
  final VoidCallback toggleTheme;
  const Layout({super.key, required this.toggleTheme});

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    CadastralScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _widgetOptions.length, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/user_profile');
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _tabController.index;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('AppMarañon'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: _navigateToProfile,
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ResponsiveWidth(
              sm: 7 / 12,
              md: 6 / 12,
              lg: 5 / 12,
              xl: 4 / 12,
              xxl: 3 / 12,
              child: Material(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(70),
                clipBehavior: Clip.antiAlias,
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(70),
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  indicatorColor: Colors.transparent,
                  dividerColor: Colors.transparent,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onPrimary,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  indicatorSize: TabBarIndicatorSize.label,
                  indicatorPadding: const EdgeInsets.symmetric(vertical: 4.0),
                  tabs: [
                    _buildTab(
                      icon: Icons.home,
                      text: 'Inicio',
                      isActive: activeIndex == 0,
                    ),
                    _buildTab(
                      icon: Icons.edit_document,
                      text: 'Catastro',
                      isActive: activeIndex == 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _widgetOptions,
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String text,
    required bool isActive,
  }) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
