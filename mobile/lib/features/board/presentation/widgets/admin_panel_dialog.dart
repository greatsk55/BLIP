import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../../core/constants/app_colors.dart';

/// 관리자 패널 다이얼로그
/// web: AdminPanel.tsx 동일 UX
class AdminPanelDialog extends StatefulWidget {
  final String boardId;
  final Future<void> Function() onForgetToken;
  final Future<String?> Function() onDestroyBoard;
  final String? currentSubtitle;
  final Future<String?> Function(String subtitle)? onUpdateSubtitle;
  final Future<({String? inviteCode, String? error})> Function()? onRotateInviteCode;

  const AdminPanelDialog({
    super.key,
    required this.boardId,
    required this.onForgetToken,
    required this.onDestroyBoard,
    this.currentSubtitle,
    this.onUpdateSubtitle,
    this.onRotateInviteCode,
  });

  /// 다이얼로그 표시
  static Future<void> show(
    BuildContext context, {
    required String boardId,
    required Future<void> Function() onForgetToken,
    required Future<String?> Function() onDestroyBoard,
    String? currentSubtitle,
    Future<String?> Function(String subtitle)? onUpdateSubtitle,
    Future<({String? inviteCode, String? error})> Function()? onRotateInviteCode,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AdminPanelDialog(
        boardId: boardId,
        onForgetToken: onForgetToken,
        onDestroyBoard: onDestroyBoard,
        currentSubtitle: currentSubtitle,
        onUpdateSubtitle: onUpdateSubtitle,
        onRotateInviteCode: onRotateInviteCode,
      ),
    );
  }

  @override
  State<AdminPanelDialog> createState() => _AdminPanelDialogState();
}

class _AdminPanelDialogState extends State<AdminPanelDialog> {
  bool _showDestroyConfirm = false;
  bool _destroying = false;
  bool _showSubtitleEdit = false;
  bool _subtitleSaving = false;
  late final TextEditingController _subtitleController;

  // 초대 코드 관리
  bool _rotating = false;
  String? _newInviteCode;

  @override
  void initState() {
    super.initState();
    _subtitleController = TextEditingController(text: widget.currentSubtitle ?? '');
  }

  @override
  void dispose() {
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _handleDestroy() async {
    setState(() => _destroying = true);
    final error = await widget.onDestroyBoard();
    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _destroying = false);
    }
  }

  Future<void> _handleRotateInviteCode() async {
    if (widget.onRotateInviteCode == null) return;
    setState(() => _rotating = true);
    final result = await widget.onRotateInviteCode!();
    if (!mounted) return;
    setState(() {
      _rotating = false;
      if (result.inviteCode != null) {
        _newInviteCode = result.inviteCode;
      }
    });
    if (result.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error!),
          backgroundColor: AppColors.glitchRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(
            child: Text(
              l10n.boardAdminPanel,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: _showDestroyConfirm
          ? _buildDestroyConfirm(l10n, isDark)
          : _buildMenu(l10n, isDark),
    );
  }

  Widget _buildMenu(AppLocalizations l10n, bool isDark) {
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 부제목 편집
        if (widget.onUpdateSubtitle != null && !_showSubtitleEdit)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _showSubtitleEdit = true),
              icon: Icon(Icons.subtitles_outlined, size: 18, color: signalGreen),
              label: Text(
                l10n.boardAdminEditSubtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
          ),

        // 부제목 편집 입력 영역
        if (_showSubtitleEdit) ...[
          TextField(
            controller: _subtitleController,
            autofocus: true,
            maxLength: 100,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(
              hintText: l10n.boardAdminSubtitlePlaceholder,
              counterText: '',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: signalGreen),
              ),
            ),
            onSubmitted: (_) => _handleSaveSubtitle(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _subtitleController.text = widget.currentSubtitle ?? '';
                    _showSubtitleEdit = false;
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Text(l10n.commonCancel,
                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _subtitleSaving ? null : _handleSaveSubtitle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: signalGreen,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: _subtitleSaving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n.boardAdminSubtitleSave,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],

        if (_showSubtitleEdit || widget.onUpdateSubtitle != null)
          const SizedBox(height: 12),

        // 초대 코드 관리
        if (widget.onRotateInviteCode != null)
          _buildInviteCodeSection(l10n, isDark, signalGreen),

        // 관리자 토큰 해제
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              widget.onForgetToken();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.key_off, size: 18),
            label: Text(
              l10n.boardAdminForgetToken,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 커뮤니티 파쇄
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _showDestroyConfirm = true),
            icon: const Icon(Icons.delete_forever, size: 18,
                color: AppColors.glitchRed),
            label: Text(
              l10n.boardAdminDestroy,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: AppColors.glitchRed,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(
                color: AppColors.glitchRed,
                width: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCodeSection(AppLocalizations l10n, bool isDark, Color signalGreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더 + 설명
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, size: 16, color: signalGreen),
                  const SizedBox(width: 6),
                  Text(
                    l10n.boardAdminRotateInviteCode,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.boardAdminRotateInviteCodeDesc,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white54 : Colors.black45,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),

              if (_newInviteCode == null)
                // 갱신 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _rotating ? null : _handleRotateInviteCode,
                    icon: _rotating
                        ? SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: signalGreen,
                            ),
                          )
                        : Icon(Icons.refresh, size: 16, color: signalGreen),
                    label: Text(
                      l10n.boardAdminRotateInviteCode,
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                        color: signalGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(color: signalGreen.withValues(alpha: 0.3)),
                    ),
                  ),
                )
              else ...[
                // 새 초대 링크 표시
                Text(
                  l10n.boardAdminNewInviteCode,
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: signalGreen.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                // 링크 + 복사 버튼
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                    border: Border.all(color: signalGreen.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'blip.im/board/${widget.boardId}#k=${Uri.encodeComponent(_newInviteCode!)}',
                          style: TextStyle(
                            fontSize: 9,
                            fontFamily: 'monospace',
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          final link = 'https://blip.im/board/${widget.boardId}#k=${Uri.encodeComponent(_newInviteCode!)}';
                          Clipboard.setData(ClipboardData(text: link));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.boardAdminInviteLinkCopied),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(Icons.copy, size: 14, color: signalGreen),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                // 경고: 이전 링크 무효화
                Text(
                  l10n.boardAdminOldLinksInvalidated,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: AppColors.glitchRed.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                // 안심: 기존 멤버 영향 없음
                Text(
                  l10n.boardAdminExistingMembersUnaffected,
                  style: TextStyle(
                    fontSize: 9,
                    fontFamily: 'monospace',
                    color: signalGreen.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _handleSaveSubtitle() async {
    if (widget.onUpdateSubtitle == null) return;
    setState(() => _subtitleSaving = true);
    final error = await widget.onUpdateSubtitle!(_subtitleController.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _subtitleSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.glitchRed,
        ),
      );
      return;
    }
    setState(() {
      _subtitleSaving = false;
      _showSubtitleEdit = false;
    });
  }

  Widget _buildDestroyConfirm(AppLocalizations l10n, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded,
            size: 40, color: AppColors.glitchRed),
        const SizedBox(height: 12),
        Text(
          l10n.boardAdminDestroyWarning,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.glitchRed,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showDestroyConfirm = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  l10n.commonCancel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _destroying ? null : _handleDestroy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.glitchRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _destroying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.boardAdminConfirmDestroy,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
