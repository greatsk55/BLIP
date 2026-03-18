import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/ad_service.dart';

/// 그룹 채팅방 생성 화면
class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({super.key});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final _titleController = TextEditingController();
  final _api = ApiClient();
  bool _creating = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_creating) return;
    setState(() => _creating = true);

    try {
      final title = _titleController.text.trim().isEmpty
          ? 'Untitled Group'
          : _titleController.text.trim();

      final result = await _api.createGroupRoom(title: title);
      if (!mounted) return;

      if (result['error'] != null) {
        _showError(result['error'] as String);
        return;
      }

      final roomId = result['roomId'] as String;
      final password = result['password'] as String;
      final adminToken = result['adminToken'] as String;

      await AdService.instance.showInterstitial();
      if (!mounted) return;

      // 생성 결과 화면으로 이동
      context.push('/group/$roomId', extra: {
        'password': password,
        'adminToken': adminToken,
        'isAdmin': true,
        'justCreated': true,
      });
    } catch (_) {
      if (mounted) _showError('NETWORK_ERROR');
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  void _showError(String code) {
    final l10n = AppLocalizations.of(context)!;
    final msg = code == 'TOO_MANY_REQUESTS'
        ? l10n.errorRateLimit
        : l10n.errorGeneric;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.group_add, size: 48, color: signalGreen),
              const SizedBox(height: 24),
              Text(
                l10n.groupCreateTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.groupCreateSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: ghostGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _titleController,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: l10n.groupCreateNameHint,
                  hintStyle: TextStyle(
                    color: ghostGrey.withValues(alpha: 0.5),
                  ),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _creating ? null : _createGroup,
                  child: _creating
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark
                                ? AppColors.voidBlackDark
                                : AppColors.white,
                          ),
                        )
                      : Text(l10n.groupCreateButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
