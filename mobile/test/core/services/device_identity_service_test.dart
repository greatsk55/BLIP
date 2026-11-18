import 'package:blip/core/services/device_identity_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

MockSecureStorage storageFor(Map<String, String> values) {
  final storage = MockSecureStorage();
  when(
    () => storage.read(key: any(named: 'key')),
  ).thenAnswer((call) async => values[call.namedArguments[#key]]);
  when(
    () => storage.write(
      key: any(named: 'key'),
      value: any(named: 'value'),
    ),
  ).thenAnswer((call) async {
    values[call.namedArguments[#key] as String] =
        call.namedArguments[#value] as String;
  });
  return storage;
}

void main() {
  test('asynchronous storage write failure is retried without a temporary ID', () async {
    final values = <String, String>{};
    final storage = storageFor(values);
    var writes = 0;
    when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((call) async {
      if (writes++ == 0) throw StateError('write unavailable');
      values[call.namedArguments[#key] as String] = call.namedArguments[#value] as String;
    });
    final identity = DeviceIdentityService(storage: storage);
    await expectLater(identity.getFingerprint(), throwsStateError);
    expect(values, isEmpty);
    final saved = await identity.getFingerprint();
    expect(values.values.single, saved);
    expect(await identity.getFingerprint(), saved);
  });
  test(
    'two installations in the same timezone have independent identities',
    () async {
      final first = DeviceIdentityService(storage: storageFor({}));
      final second = DeviceIdentityService(storage: storageFor({}));
      final a = await first.getFingerprint();
      final b = await second.getFingerprint();
      expect(a, matches(RegExp(r'^[a-f0-9]{64}$')));
      expect(b, isNot(a));
    },
  );

  test(
    'identity survives a service restart and concurrent callers agree',
    () async {
      final values = <String, String>{};
      final first = DeviceIdentityService(storage: storageFor(values));
      final ids = await Future.wait(
        List.generate(8, (_) => first.getFingerprint()),
      );
      expect(ids.toSet(), hasLength(1));
      final restarted = DeviceIdentityService(storage: storageFor(values));
      expect(await restarted.getFingerprint(), ids.first);
    },
  );

  test(
    'storage failure never falls back to a shared or temporary identity',
    () async {
      final storage = MockSecureStorage();
      when(
        () => storage.read(key: any(named: 'key')),
      ).thenThrow(StateError('storage unavailable'));
      final identity = DeviceIdentityService(storage: storage);
      await expectLater(identity.getFingerprint(), throwsStateError);
      verifyNever(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      );
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'a' * 64);
      expect(await identity.getFingerprint(), 'a' * 64);
    },
  );
}
