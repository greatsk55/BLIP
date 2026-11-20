import 'dart:async';
import 'package:blip/core/widgets/deferred_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'first screen renders while optional SDK startup is still pending',
    (tester) async {
      final pending = Completer<void>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DeferredStartup(
            initialize: () {
              calls++;
              return pending.future;
            },
            child: const Text('BLIP ready'),
          ),
        ),
      );
      expect(find.text('BLIP ready'), findsOneWidget);
      expect(calls, 1);
      await tester.pump();
      expect(calls, 1);
      pending.complete();
      await tester.pump();
    },
  );

  testWidgets('optional startup failure does not remove the app or escape', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeferredStartup(
          initialize: () async => throw StateError('advertising unavailable'),
          child: const Text('BLIP ready'),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('BLIP ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
