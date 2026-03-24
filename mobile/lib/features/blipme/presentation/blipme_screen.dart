import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_room.dart';
import '../providers/blipme_provider.dart';

class BlipMeScreen extends ConsumerStatefulWidget {
  const BlipMeScreen({super.key});

  @override
  ConsumerState<BlipMeScreen> createState() => _BlipMeScreenState();
}

class _BlipMeScreenState extends ConsumerState<BlipMeScreen> {
  bool _confirmDelete = false;

  String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://blip-blip.vercel.app';

  String _blipMeUrl(String linkId) => '$_baseUrl/m/$linkId';

  Future<void> _copyLink(String linkId) async {
    await Clipboard.setData(ClipboardData(text: _blipMeUrl(linkId)));
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _shareLink(String linkId) async {
    await Share.share(_blipMeUrl(linkId));
  }

  void _handleDelete() {
    if (!_confirmDelete) {
      setState(() => _confirmDelete = true);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _confirmDelete = false);
      });
      return;
    }
    ref.read(blipMeProvider.notifier).deleteLink();
    setState(() => _confirmDelete = false);
  }

  Future<void> _joinRoom(IncomingConnection conn) async {
    final storage = LocalStorageService();
    final now = DateTime.now().millisecondsSinceEpoch;
    await storage.saveRoom(
      SavedRoom(
        roomId: conn.roomId,
        isCreator: false,
        createdAt: now,
        lastAccessedAt: now,
      ),
      conn.password,
    );
    ref.read(blipMeProvider.notifier).clearIncoming();
    if (mounted) {
      context.push('/room/${conn.roomId}', extra: conn.password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(blipMeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'BLIP me',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            letterSpacing: 2,
          ),
        ),
        actions: [
          if (state.linkId != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.listening ? Icons.radio : Icons.wifi_off,
                    size: 12,
                    color: state.listening ? signalGreen : ghostGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    state.listening
                        ? l10n.blipMeListening
                        : l10n.blipMeOffline,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: state.listening ? signalGreen : ghostGrey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: state.loading
                ? const Center(child: CircularProgressIndicator())
                : state.linkId == null
                    ? _buildCreateView(l10n, signalGreen, ghostGrey, isDark)
                    : _buildManageView(
                        l10n, state, signalGreen, ghostGrey, borderColor, isDark),
          ),
          // 수신 알림
          if (state.incomingConnection != null)
            _buildIncomingOverlay(
                l10n, state.incomingConnection!, signalGreen, ghostGrey, borderColor, isDark),
        ],
      ),
    );
  }

  Widget _buildCreateView(
    AppLocalizations l10n,
    Color signalGreen,
    Color ghostGrey,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 48, color: signalGreen),
            const SizedBox(height: 24),
            Text(
              l10n.blipMeCreateTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.blipMeCreateDescription,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ghostGrey, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(blipMeProvider.notifier).createLink(),
                child: Text(l10n.blipMeCreateButton),
              ),
            ),
            if (ref.watch(blipMeProvider).error != null) ...[
              const SizedBox(height: 12),
              Text(
                ref.watch(blipMeProvider).error == 'TOO_MANY_REQUESTS'
                    ? l10n.blipMeRateLimited
                    : l10n.blipMeError,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.glitchRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManageView(
    AppLocalizations l10n,
    BlipMeState state,
    Color signalGreen,
    Color ghostGrey,
    Color borderColor,
    bool isDark,
  ) {
    final linkId = state.linkId!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL 표시
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.blipMeYourLink,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: ghostGrey,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _blipMeUrl(linkId),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: signalGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyLink(linkId),
                        icon: Icon(Icons.copy, size: 16, color: signalGreen),
                        label: Text(
                          'COPY',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _shareLink(linkId),
                        icon: Icon(Icons.share, size: 16, color: signalGreen),
                        label: Text(
                          'SHARE',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 통계
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.blipMeTotalConnections,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: ghostGrey,
                  ),
                ),
                Text(
                  '${state.useCount}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 안내
          Text(
            l10n.blipMeHowItWorks,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: ghostGrey,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // 액션 버튼
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(blipMeProvider.notifier).regenerateLink(),
                  icon: Icon(Icons.refresh, size: 16, color: signalGreen),
                  label: Text(
                    l10n.blipMeRegenerate,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleDelete,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: _confirmDelete
                        ? AppColors.glitchRed
                        : ghostGrey,
                  ),
                  label: Text(
                    _confirmDelete
                        ? l10n.blipMeConfirmDelete
                        : l10n.blipMeDelete,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: _confirmDelete
                          ? AppColors.glitchRed
                          : null,
                    ),
                  ),
                  style: _confirmDelete
                      ? OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.glitchRed),
                        )
                      : null,
                ),
              ),
            ],
          ),

          // 에러
          if (state.error != null) ...[
            const SizedBox(height: 12),
            Text(
              state.error == 'TOO_MANY_REQUESTS'
                  ? l10n.blipMeRateLimited
                  : l10n.blipMeError,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.glitchRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomingOverlay(
    AppLocalizations l10n,
    IncomingConnection conn,
    Color signalGreen,
    Color ghostGrey,
    Color borderColor,
    bool isDark,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111111) : Colors.white,
            border: Border.all(color: signalGreen),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: signalGreen.withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active,
                      color: signalGreen, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.blipMeIncomingTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.blipMeIncomingDescription,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: ghostGrey,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _joinRoom(conn),
                        child: Text(l10n.blipMeJoinRoom),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () =>
                          ref.read(blipMeProvider.notifier).clearIncoming(),
                      child: Text(l10n.blipMeDismiss),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
