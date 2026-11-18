import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Installation-scoped identity for anonymous points. Never derive it from
/// timezone, locale, model, or another value shared by unrelated users.
class DeviceIdentityService {
  DeviceIdentityService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static final instance = DeviceIdentityService();
  static const _key = 'blip_prediction_installation_v1';
  static final _validFingerprint = RegExp(r'^[a-f0-9]{64}$');
  final FlutterSecureStorage _storage;
  Future<String>? _pending;

  Future<String> getFingerprint() async {
    final existing = _pending;
    if (existing != null) return existing;
    final loading = _load();
    _pending = loading;
    try {
      return await loading;
    } catch (_) {
      if (identical(_pending, loading)) _pending = null;
      rethrow;
    }
  }

  Future<String> _load() async {
      final saved = await _storage.read(key: _key);
      if (saved != null && _validFingerprint.hasMatch(saved)) return saved;
      final random = Random.secure();
      final fingerprint = sha256
          .convert(List<int>.generate(32, (_) => random.nextInt(256)))
          .toString();
      await _storage.write(key: _key, value: fingerprint);
      return fingerprint;
  }
}
