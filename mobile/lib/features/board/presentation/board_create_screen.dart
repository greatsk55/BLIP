import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/crypto/crypto.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_board.dart';

/// 커뮤니티 생성 화면
/// web: BoardCreateClient.tsx + BoardCreatedView.tsx 동일 플로우
class BoardCreateScreen extends StatefulWidget {
  const BoardCreateScreen({super.key});

  @override
  State<BoardCreateScreen> createState() => _BoardCreateScreenState();
}

class _BoardCreateScreenState extends State<BoardCreateScreen> {
  final _nameController = TextEditingController();
  final _api = ApiClient();
  bool _loading = false;
  String? _error;

  // 생성 완료 결과
  _CreateResult? _result;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1단계: 서버에서 boardId + password + adminToken 생성
      final createResult = await _api.createBoard(
        encryptedName: '',
        encryptedNameNonce: '',
      );

      if (createResult['error'] != null) {
        setState(() {
          _error = createResult['error'] as String;
          _loading = false;
        });
        return;
      }

      final boardId = createResult['boardId'] as String;
      final password = createResult['password'] as String;
      final adminToken = createResult['adminToken'] as String;

      // 2단계: 비밀번호에서 암호화 키 유도 → 커뮤니티 이름 암호화 → 서버 업데이트
      final derived = deriveKeysFromPassword(password, boardId);
      final encName = encryptSymmetric(name, derived.encryptionSeed);
      final authKeyHash = hashAuthKey(derived.authKey);

      final updateResult = await _api.updateBoardName(
        boardId: boardId,
        authKeyHash: authKeyHash,
        encryptedName: encName.ciphertext,
        encryptedNameNonce: encName.nonce,
      );

      if (updateResult['success'] != true) {
        setState(() {
          _error = (updateResult['error'] as String?) ?? 'UPDATE_FAILED';
          _loading = false;
        });
        return;
      }

      // 3단계: 로컬 저장 (비밀번호 + 관리자 토큰 + 보드 메타)
      const secureStorage = FlutterSecureStorage();
      await secureStorage.write(
        key: 'blip-board-$boardId',
        value: password,
      );
      await secureStorage.write(
        key: 'blip-board-admin-$boardId',
        value: adminToken,
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      await LocalStorageService().saveBoard(SavedBoard(
        boardId: boardId,
        boardName: name,
        joinedAt: now,
        lastAccessedAt: now,
      ));

      setState(() {
        _result = _CreateResult(
          boardId: boardId,
          password: password,
          adminToken: adminToken,
        );
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'CREATION_FAILED';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      return _CreatedView(
        result: _result!,
        onEnter: () => context.go('/board/${_result!.boardId}'),
      );
    }
    return _CreateForm(
      nameController: _nameController,
      loading: _loading,
      error: _error,
      onCreate: _create,
    );
  }
}

// ─── 생성 결과 데이터 ───

class _CreateResult {
  final String boardId;
  final String password;
  final String adminToken;

  const _CreateResult({
    required this.boardId,
    required this.password,
    required this.adminToken,
  });
}

// ─── 생성 폼 ───

class _CreateForm extends StatelessWidget {
  final TextEditingController nameController;
  final bool loading;
  final String? error;
  final VoidCallback onCreate;

  const _CreateForm({
    required this.nameController,
    required this.loading,
    this.error,
    required this.onCreate,
  });

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
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.forum_outlined,
                  size: 32,
                  color: signalGreen.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 24),

                // 서브타이틀
                Text(
                  l10n.boardCreateSubtitle.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: ghostGrey,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 32),

                // 이름 입력
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.center,
                  maxLength: 50,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    letterSpacing: 2,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.boardCreateNamePlaceholder,
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      color: ghostGrey.withValues(alpha: 0.3),
                    ),
                    counterText: '',
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: signalGreen, width: 2),
                    ),
                  ),
                  autofocus: true,
                  onSubmitted: (_) => onCreate(),
                ),

                // 에러
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    error!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: AppColors.glitchRed,
                      letterSpacing: 2,
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // 생성 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: loading ? null : onCreate,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: signalGreen),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: signalGreen,
                            ),
                          )
                        : Text(
                            l10n.boardCreateButton.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: signalGreen,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 생성 완료 화면 (web: BoardCreatedView.tsx) ───

class _CreatedView extends StatelessWidget {
  final _CreateResult result;
  final VoidCallback onEnter;

  const _CreatedView({
    required this.result,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final signalGreen =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;
    final ghostGrey =
        isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;
    final shareUrl = 'https://blip-blip.vercel.app/board/${result.boardId}';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 타이틀
                Text(
                  l10n.boardCreateTitle.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: signalGreen,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 32),

                // 비밀번호
                _InfoBlock(
                  label: l10n.boardCreatePassword,
                  value: result.password,
                  valueStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    letterSpacing: 6,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  borderColor: signalGreen.withValues(alpha: 0.2),
                  labelColor: ghostGrey,
                ),
                const SizedBox(height: 16),

                // 관리자 토큰
                _InfoBlock(
                  label: l10n.boardCreateAdminToken,
                  value: result.adminToken,
                  valueStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: ghostGrey,
                  ),
                  borderColor: AppColors.glitchRed.withValues(alpha: 0.2),
                  labelColor: ghostGrey,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.boardCreateAdminTokenWarning.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: AppColors.glitchRed.withValues(alpha: 0.5),
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 공유 링크
                _InfoBlock(
                  label: l10n.boardCreateShareLink,
                  value: shareUrl,
                  valueStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: ghostGrey,
                  ),
                  borderColor: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  labelColor: ghostGrey,
                  onShare: () => Share.share(shareUrl),
                ),
                const SizedBox(height: 32),

                // 입장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: onEnter,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: signalGreen),
                      shape: const RoundedRectangleBorder(),
                    ),
                    child: Text(
                      l10n.boardCreateEnter.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: signalGreen,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 정보 블록 (비밀번호, 토큰, 링크 공용) ───

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle valueStyle;
  final Color borderColor;
  final Color labelColor;
  final VoidCallback? onShare;

  const _InfoBlock({
    required this.label,
    required this.value,
    required this.valueStyle,
    required this.borderColor,
    required this.labelColor,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: labelColor.withValues(alpha: 0.6),
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(value, style: valueStyle),
              ),
              const SizedBox(width: 8),
              // 복사 버튼
              IconButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.commonCopied),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              // 공유 버튼 (링크만)
              if (onShare != null)
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.share, size: 16),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
