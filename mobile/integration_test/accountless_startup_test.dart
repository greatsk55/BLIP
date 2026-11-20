import 'package:blip/app.dart';
import 'package:blip/features/home/presentation/home_screen.dart';
import 'package:blip/features/settings/presentation/settings_screen.dart';
import 'package:blip/main.dart' as app;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens the real app and settings without an Apple account', (
    tester,
  ) async {
    await app.main();
    for (var attempt = 0; attempt < 14; attempt++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.byType(HomeScreen).evaluate().isNotEmpty) break;
    }
    expect(find.byType(HomeScreen), findsOneWidget);
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // Scene startup must register BLIP's own channels as well as Flutter plugins.
      await const MethodChannel(
        'com.bakkum.blip/audio',
      ).invokeMethod<void>('playBeep');
    }

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BlipApp)),
    );
    final router = container.read(routerProvider);
    router.go('/login?from=%2Fsettings');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/settings');
  });
}
