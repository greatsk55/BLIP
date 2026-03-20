import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/analytics_service.dart';

/// 그룹방 생성 결과 화면 (비밀번호 + 관리자 토큰 + 공유 링크)
class GroupCreatedView extends StatefulWidget {
  final String roomId;
  final String password;
  final String adminToken;
  final VoidCallback onEnterChat;

  const GroupCreatedView({
    super.key,
    required this.roomId,
    required this.password,
    required this.adminToken,
    required this.onEnterChat,
  });

  @override
  State<GroupCreatedView> createState() => _GroupCreatedViewState();
}

class _GroupCreatedViewState extends State<GroupCreatedView> {
  bool _includeKey = true;

  String get _baseLink {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://blip-blip.vercel.app';
    return '$baseUrl/group/${widget.roomId}';
  }

  String get _shareLink {
    if (_includeKey) {
      return '$_baseLink?k=${Uri.encodeComponent(widget.password)}';
    }
    return _baseLink;
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commonCopied),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              const SizedBox(height: 48),

              // Title
              Text(
                l10n.groupCreatedTitle.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 6,
                  color: signalGreen,
                ),
              ),
              const SizedBox(height: 32),

              // ACCESS KEY
              _LabeledField(
                label: l10n.chatAccessKey.toUpperCase(),
                value: widget.password,
                valueStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onCopy: () => _copy(widget.password),
                signalGreen: signalGreen,
                ghostGrey: ghostGrey,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // ADMIN TOKEN
              _LabeledField(
                label: l10n.groupAdminToken.toUpperCase(),
                value: widget.adminToken,
                valueStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  color: AppColors.glitchRed,
                ),
                onCopy: () => _copy(widget.adminToken),
                signalGreen: signalGreen,
                ghostGrey: ghostGrey,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.groupAdminTokenWarning.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 2,
                  color: AppColors.glitchRed.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),

              // SHARE LINK
              Text(
                l10n.chatShareLink.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 3,
                  color: ghostGrey.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.02)
                      : Colors.black.withValues(alpha: 0.02),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _shareLink,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: ghostGrey,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _CopyIcon(
                      onTap: () => _copy(_shareLink),
                      color: ghostGrey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Include key toggle
              GestureDetector(
                onTap: () => setState(() => _includeKey = !_includeKey),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _includeKey
                            ? signalGreen.withValues(alpha: 0.8)
                            : ghostGrey.withValues(alpha: 0.2),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _includeKey
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isDark ? AppColors.voidBlackDark : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.chatIncludeKey.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        letterSpacing: 2,
                        color: ghostGrey.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Share button
              Builder(builder: (ctx) {
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () async {
                      final text = _includeKey
                          ? l10n.chatShareMessageLinkOnly(_shareLink)
                          : l10n.chatShareMessage(_shareLink, widget.password);
                      final box = ctx.findRenderObject() as RenderBox?;
                      AnalyticsService.instance.logShareLink(roomType: 'group');
                      await Share.share(
                        text,
                        sharePositionOrigin: box != null
                            ? box.localToGlobal(Offset.zero) & box.size
                            : null,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: signalGreen),
                      foregroundColor: signalGreen,
                      shape: const RoundedRectangleBorder(),
                      textStyle: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        letterSpacing: 3,
                      ),
                    ),
                    child: Text(l10n.commonShare.toUpperCase()),
                  ),
                );
              }),
              const SizedBox(height: 16),

              // Enter chat button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: widget.onEnterChat,
                  child: Text(l10n.groupEnterChat),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  final VoidCallback onCopy;
  final Color signalGreen;
  final Color ghostGrey;
  final bool isDark;

  const _LabeledField({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.onCopy,
    required this.signalGreen,
    required this.ghostGrey,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 3,
            color: ghostGrey.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: signalGreen.withValues(alpha: 0.2)),
            color: isDark
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(value, style: valueStyle)),
              const SizedBox(width: 8),
              _CopyIcon(onTap: onCopy, color: ghostGrey),
            ],
          ),
        ),
      ],
    );
  }
}

class _CopyIcon extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;

  const _CopyIcon({required this.onTap, required this.color});

  @override
  State<_CopyIcon> createState() => _CopyIconState();
}

class _CopyIconState extends State<_CopyIcon> {
  bool _copied = false;

  void _handleTap() {
    widget.onTap();
    setState(() => _copied = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _copied
              ? Icon(Icons.check, size: 16, color: widget.color,
                  key: const ValueKey('check'))
              : Icon(Icons.copy, size: 16, color: widget.color,
                  key: const ValueKey('copy')),
        ),
      ),
    );
  }
}
