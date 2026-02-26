import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/models/saved_room.dart';
import '../providers/chat_provider.dart';
import '../providers/webrtc_provider.dart';
import 'widgets/password_entry.dart';
import 'widgets/room_created_view.dart';
import 'widgets/chat_room_view.dart';
import 'widgets/room_destroyed_overlay.dart';

/// 채팅 화면 최상위 상태 (비밀번호 입력 전/후)
enum _ScreenPhase { passwordRequired, chatting }

class ChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? initialPassword;

  const ChatScreen({
    super.key,
    required this.roomId,
    this.initialPassword,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  late _ScreenPhase _phase;
  String? _password;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.initialPassword != null) {
      _password = widget.initialPassword;
      _phase = _ScreenPhase.chatting; // 바로 ChatWrapper 진입 (Presence 연결)
    } else {
      _phase = _ScreenPhase.passwordRequired;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('[ChatScreen] lifecycle: $state');
    if (_password == null) return;
    final params = (roomId: widget.roomId, password: _password!);
    final notifier = ref.read(chatNotifierProvider(params).notifier);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[ChatScreen] resumed → reconnectPresence()');
        notifier.reconnectPresence();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void deactivate() {
    // ref.invalidate()는 dispose()에서 호출하면 이미 Element가 unmount 중이라
    // "Cannot use ref after disposed" 에러 발생 → deactivate()에서 호출
    if (_password != null) {
      final params = (roomId: widget.roomId, password: _password!);
      ref.invalidate(webRtcNotifierProvider(params));
      ref.invalidate(chatNotifierProvider(params));
    }
    super.deactivate();
  }

  @override
  void dispose() {
    debugPrint('[ChatScreen] dispose called');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPasswordVerified(String password) {
    // 로컬 저장 (참여자 입장)
    final now = DateTime.now().millisecondsSinceEpoch;
    LocalStorageService().saveRoom(
      SavedRoom(
        roomId: widget.roomId,
        isCreator: false,
        createdAt: now,
        lastAccessedAt: now,
      ),
      password,
    );

    setState(() {
      _password = password;
      _phase = _ScreenPhase.chatting;
    });
  }

  @override
  Widget build(BuildContext context) {
    // chatting phase는 _ChatWrapper 내부에서 뒤로가기 제공 → AppBar 생략
    final showAppBar = _phase != _ScreenPhase.chatting;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              leading: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            )
          : null,
      body: SafeArea(
        top: !showAppBar,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (_phase) {
      case _ScreenPhase.passwordRequired:
        return PasswordEntry(
          roomId: widget.roomId,
          onVerified: _onPasswordVerified,
        );

      case _ScreenPhase.chatting:
        return _ChatWrapper(
          roomId: widget.roomId,
          password: _password!,
        );
    }
  }
}

/// ChatNotifier 상태를 감시하여 적절한 뷰 자동 전환
/// - connecting/loading → 로딩
/// - chatting + !peerConnected → RoomCreatedView (링크+비밀번호 공유, 대기)
/// - chatting + peerConnected → ChatRoomView (실제 채팅)
/// - destroyed/error → 에러/파쇄 뷰
class _ChatWrapper extends ConsumerWidget {
  final String roomId;
  final String password;

  const _ChatWrapper({required this.roomId, required this.password});

  ({String roomId, String password}) get _params =>
      (roomId: roomId, password: password);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatNotifierProvider(_params));

    switch (chatState.status) {
      case ChatStatus.connecting:
      case ChatStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case ChatStatus.chatting:
        // 상대방 미접속 → 링크/비밀번호 공유 화면 (Presence가 자동 감지)
        if (!chatState.peerConnected) {
          return Column(
            children: [
              // 뒤로가기 헤더
              _BackHeader(),
              Expanded(
                child: RoomCreatedView(
                  roomId: roomId,
                  password: password,
                ),
              ),
            ],
          );
        }
        // 상대방 접속됨 → 실제 채팅
        return ChatRoomView(
          roomId: roomId,
          password: password,
          onDestroyed: () {
            ref.read(chatNotifierProvider(_params).notifier).disconnect();
          },
        );

      case ChatStatus.destroyed:
        return RoomDestroyedOverlay(
          onClose: () => Navigator.of(context).popUntil((r) => r.isFirst),
        );

      case ChatStatus.roomFull:
      case ChatStatus.expired:
      case ChatStatus.error:
        return _ErrorView(status: chatState.status);

      // ChatWrapper에서 도달하지 않는 상태
      case ChatStatus.passwordRequired:
      case ChatStatus.created:
        return const Center(child: CircularProgressIndicator());
    }
  }
}

/// 간단한 뒤로가기 헤더 (RoomCreatedView 상단)
class _BackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ChatStatus status;

  const _ErrorView({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (status) {
      ChatStatus.expired => l10n.chatExpired,
      ChatStatus.roomFull => l10n.chatRoomFull,
      _ => l10n.errorGeneric,
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.glitchRed),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(l10n.commonBack),
          ),
        ],
      ),
    );
  }
}
