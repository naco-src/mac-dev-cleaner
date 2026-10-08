import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controller/cleaner_controller.dart';
import 'screens/doctor_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'widgets/fda_onboarding.dart';

class MacDevCleanerApp extends StatelessWidget {
  const MacDevCleanerApp({super.key, this.controller, this.updaterController});

  final CleanerController? controller;
  final DesktopUpdaterController? updaterController;

  @override
  Widget build(BuildContext context) {
    final updater = updaterController;
    return ChangeNotifierProvider(
      create: (_) => controller ?? CleanerController()
        ..refreshDiskSpace(),
      child: MaterialApp(
        title: 'Mac Dev Cleaner',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
          useMaterial3: true,
        ),
        builder: (context, child) {
          if (updater == null || child == null) {
            return child ?? const SizedBox.shrink();
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              child,
              UpdateDialogListener(controller: updater),
            ],
          );
        },
        home: _AppShell(updaterController: updater),
      ),
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell({this.updaterController});

  final DesktopUpdaterController? updaterController;

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

  Future<void> _checkForUpdates() async {
    final controller = widget.updaterController;
    if (controller == null) {
      return;
    }
    final result = await controller.checkForUpdates();
    if (!mounted) {
      return;
    }
    await showManualUpdateCheckResultDialog(
      context,
      controller: controller,
      result: result,
      // Available / policy / fresh-install: [UpdateDialogListener] shows the flow dialog.
      showAvailableUpdate: false,
    );
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
          if (widget.updaterController != null)
            IconButton(
              icon: const Icon(Icons.system_update_alt_outlined),
              tooltip: 'Check for updates',
              onPressed: _checkForUpdates,
            ),
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
