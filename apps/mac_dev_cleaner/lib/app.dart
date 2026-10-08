import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/cleaner_controller.dart';
import 'screens/doctor_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/fda_onboarding.dart';

class MacDevCleanerApp extends StatelessWidget {
  const MacDevCleanerApp({super.key, this.controller});

  final CleanerController? controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => controller ?? CleanerController()
        ..refreshDiskSpace(),
      child: MaterialApp(
        title: 'Mac Dev Cleaner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
          useMaterial3: true,
        ),
        home: const _AppShell(),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFda());
  }

  Future<void> _maybeShowFda() async {
    if (!mounted) {
      return;
    }
    if (await shouldShowFdaOnboarding()) {
      if (!mounted) {
        return;
      }
      await showFdaOnboardingSheet(context, onDismiss: () {});
    }
  }

  Future<void> _showFdaAgain() async {
    await showFdaOnboardingSheet(context, onDismiss: () {});
  }

  @override
  Widget build(BuildContext context) {
    const destinations = [
      NavigationRailDestination(icon: Icon(Icons.list), label: Text('Scan')),
      NavigationRailDestination(
        icon: Icon(Icons.medical_services_outlined),
        label: Text('Doctor'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.history),
        label: Text('History'),
      ),
    ];

    final body = switch (_index) {
      0 => const HomeScreen(),
      1 => const DoctorScreen(),
      _ => const HistoryScreen(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mac Dev Cleaner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Full Disk Access guide',
            onPressed: _showFdaAgain,
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: body),
        ],
      ),
    );
  }
}
