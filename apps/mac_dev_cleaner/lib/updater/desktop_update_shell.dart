import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/material.dart';

/// Hosts [UpdateCard] above [child] without putting [child] in a scroll view.
///
/// [DesktopUpdateWidget] wraps content in a [CustomScrollView], which breaks
/// a full-height [Scaffold] child (unbounded height).
class DesktopUpdateShell extends StatelessWidget {
  const DesktopUpdateShell({
    super.key,
    required this.controller,
    required this.child,
  });

  final DesktopUpdaterController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DesktopUpdaterInheritedNotifier(
      controller: controller,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (_blocksAppContent(controller.state)) {
            return Center(child: UpdateCard(controller: controller));
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UpdateCard(controller: controller),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }

  bool _blocksAppContent(UpdateState state) {
    return switch (state) {
      UpdateBlockedBySupportPolicy() => true,
      UpdateFreshInstallRequired(:final mandatory) => mandatory,
      _ => false,
    };
  }
}
