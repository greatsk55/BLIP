import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';

/// 그룹방 비밀번호 입력 (1:1과 동일 패턴, API만 다름)
class GroupPasswordEntry extends StatefulWidget {
  final String roomId;
  final void Function(String password) onVerified;

  const GroupPasswordEntry({
    super.key,
    required this.roomId,
    required this.onVerified,
  });

  @override
  State<GroupPasswordEntry> createState() => _GroupPasswordEntryState();
}

class _GroupPasswordEntryState extends State<GroupPasswordEntry> {
  final _controller = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final cleaned = value.replaceAll('-', '').toUpperCase();
    if (cleaned.length > 4) {
      final formatted = '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
      if (formatted != _controller.text) {
        _controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  Future<void> _verify() async {
    final password = _controller.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result =
          await _api.verifyGroupPassword(widget.roomId, password);
      if (!mounted) return;

      if (result['valid'] == true) {
        widget.onVerified(password);
      } else {
        setState(() => _error = result['error'] as String?);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'NETWORK_ERROR');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group, size: 48, color: signalGreen),
          const SizedBox(height: 24),
          Text(
            l10n.groupJoinTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.groupJoinSubtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            onSubmitted: (_) => _verify(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
              color: signalGreen,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'XXXX-XXXX',
              hintStyle: TextStyle(
                color: (isDark
                        ? AppColors.ghostGreyDark
                        : AppColors.ghostGreyLight)
                    .withValues(alpha: 0.5),
              ),
              errorText: _error != null ? _getErrorText(l10n, _error!) : null,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
              LengthLimitingTextInputFormatter(9),
            ],
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.chatPasswordJoin),
            ),
          ),
        ],
      ),
    );
  }

  String _getErrorText(AppLocalizations l10n, String code) {
    return switch (code) {
      'INVALID_PASSWORD' => l10n.chatPasswordInvalid,
      'ROOM_NOT_FOUND' => l10n.chatRoomNotFound,
      'ROOM_DESTROYED' => l10n.groupRoomDestroyed,
      'ROOM_EXPIRED' => l10n.chatExpired,
      'ROOM_LOCKED' => l10n.groupRoomLocked,
      'NOT_GROUP_ROOM' => l10n.errorGeneric,
      'TOO_MANY_REQUESTS' => l10n.errorRateLimit,
      _ => l10n.errorGeneric,
    };
  }
}
