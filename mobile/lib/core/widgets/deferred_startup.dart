import 'dart:async';
import 'package:flutter/widgets.dart';

/// Optional platform SDKs cannot hold the first screen hostage.
class DeferredStartup extends StatefulWidget {
  const DeferredStartup({
    super.key,
    required this.initialize,
    required this.child,
  });
  final Future<void> Function() initialize;
  final Widget child;

  @override
  State<DeferredStartup> createState() => _DeferredStartupState();
}

class _DeferredStartupState extends State<DeferredStartup> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initialize());
    });
  }

  Future<void> _initialize() async {
    try {
      await widget.initialize();
    } catch (error) {
      debugPrint('[BLIP] Optional startup failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
