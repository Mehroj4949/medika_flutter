import 'package:flutter/material.dart';
import 'core/app_controller.dart';
import 'core/app_theme.dart';
import 'core/localization.dart';
import 'screens/catalog_screen.dart';
import 'screens/compare_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/select_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedikaBootstrap());
}

class MedikaBootstrap extends StatefulWidget {
  const MedikaBootstrap({super.key});
  @override
  State<MedikaBootstrap> createState() => _MedikaBootstrapState();
}

class _MedikaBootstrapState extends State<MedikaBootstrap> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..initialize();
    controller.addListener(_refresh);
  }

  void _refresh() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    controller.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MEDIKA',
      theme: buildMedikaTheme(),
      home: controller.loading
          ? const _Loading()
          : controller.error != null && controller.products.isEmpty
              ? _LoadError(controller: controller)
              : MedikaShell(controller: controller),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text('MEDIKA', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: MedikaColors.navy)), SizedBox(height: 14), CircularProgressIndicator()])));
}

class _LoadError extends StatelessWidget {
  final AppController controller;
  const _LoadError({required this.controller});
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, size: 44, color: MedikaColors.blue), const SizedBox(height: 12), Text(controller.error ?? 'Catalog error', textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton(onPressed: controller.refreshCatalog, child: const Text('Повторить'))]))));
}

class MedikaShell extends StatefulWidget {
  final AppController controller;
  const MedikaShell({super.key, required this.controller});
  @override
  State<MedikaShell> createState() => _MedikaShellState();
}

class _MedikaShellState extends State<MedikaShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final text = MedikaText(controller.language);
    final screens = [
      HomeScreen(controller: controller, changeTab: (value) => setState(() => index = value)),
      CatalogScreen(controller: controller),
      SelectScreen(controller: controller),
      FavoritesScreen(controller: controller),
      ProfileScreen(controller: controller),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final desktop = constraints.maxWidth >= 900;
      final destinations = [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: text.home),
        NavigationDestination(icon: const Icon(Icons.grid_view_outlined), selectedIcon: const Icon(Icons.grid_view_rounded), label: text.catalog),
        NavigationDestination(icon: const Icon(Icons.auto_awesome_outlined), selectedIcon: const Icon(Icons.auto_awesome), label: 'SELECT'),
        NavigationDestination(icon: const Icon(Icons.favorite_border), selectedIcon: const Icon(Icons.favorite), label: text.favorites),
        NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: text.profile),
      ];

      final content = IndexedStack(index: index, children: screens);
      final appBar = AppBar(
        titleSpacing: desktop ? 22 : 12,
        title: const Row(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 17, backgroundColor: MedikaColors.navy, child: Text('M', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))), SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('MEDIKA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)), Text('Medical Equipment', style: TextStyle(fontSize: 8, color: MedikaColors.muted))])]),
        actions: [
          if (controller.compare.isNotEmpty) Badge(label: Text('${controller.compare.length}'), child: IconButton(tooltip: text.compare, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CompareScreen(controller: controller))), icon: const Icon(Icons.compare_arrows))),
          TextButton(onPressed: controller.toggleLanguage, child: Text(controller.language.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(width: 4),
        ],
      );

      if (!desktop) {
        return Scaffold(appBar: appBar, body: content, bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), destinations: destinations));
      }

      return Scaffold(
        appBar: appBar,
        body: Row(children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (value) => setState(() => index = value),
            labelType: NavigationRailLabelType.all,
            destinations: destinations.map((e) => NavigationRailDestination(icon: e.icon, selectedIcon: e.selectedIcon, label: Text(e.label))).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: content),
        ]),
      );
    });
  }
}
