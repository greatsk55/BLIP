import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blip/l10n/app_localizations.dart';

import '../../../core/constants/app_colors.dart';
import '../providers/group_chat_provider.dart';
import 'widgets/group_created_view.dart';
import 'widgets/group_password_entry.dart';
import 'widgets/group_chat_room_view.dart';

/// 그룹 채팅 화면 (비밀번호 입력 → 채팅)
class GroupChatScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String? initialPassword;
  final String? adminToken;
  final bool isAdmin;
  final bool justCreated;

  const GroupChatScreen({
    super.key,
    required this.roomId,
    this.initialPassword,
    this.adminToken,
    this.isAdmin = false,
    this.justCreated = false,
  });

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

enum _Phase { created, passwordRequired, chatting }

class _GroupChatScreenState extends ConsumerState<GroupChatScreen>
    with WidgetsBindingObserver {
  late _Phase _phase;
  String? _password;
  String? _adminToken;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _adminToken = widget.adminToken;
    _isAdmin = widget.isAdmin;

    if (widget.justCreated && widget.initialPassword != null) {
      _password = widget.initialPassword;
      _phase = _Phase.created;
    } else if (widget.initialPassword != null) {
      _password = widget.initialPassword;
      _phase = _Phase.chatting;
    } else {
      _phase = _Phase.passwordRequired;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_password == null || _phase != _Phase.chatting) return;
    final params = GroupChatParams(
      roomId: widget.roomId,
      password: _password!,
      isAdmin: _isAdmin,
      adminToken: _adminToken,
    );
    final notifier = ref.read(groupChatNotifierProvider(params).notifier);

    if (state == AppLifecycleState.resumed) {
      notifier.reconnectPresence();
    }
  }

  @override
  void deactivate() {
    if (_password != null) {
      final params = GroupChatParams(
        roomId: widget.roomId,
        password: _password!,
        isAdmin: _isAdmin,
        adminToken: _adminToken,
      );
      ref.invalidate(groupChatNotifierProvider(params));
    }
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onPasswordVerified(String password) {
    setState(() {
      _password = password;
      _phase = _Phase.chatting;
    });
  }

  void _onEnterChat() {
    setState(() {
      _phase = _Phase.chatting;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = _phase != _Phase.chatting;

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
      case _Phase.created:
        return GroupCreatedView(
          roomId: widget.roomId,
          password: _password!,
          adminToken: _adminToken!,
          onEnterChat: _onEnterChat,
        );

      case _Phase.passwordRequired:
        return GroupPasswordEntry(
          roomId: widget.roomId,
          onVerified: _onPasswordVerified,
        );

      case _Phase.chatting:
        return _GroupChatWrapper(
          roomId: widget.roomId,
          password: _password!,
          isAdmin: _isAdmin,
          adminToken: _adminToken,
        );
    }
  }
}

/// 그룹 채팅 상태 감시 및 뷰 전환
class _GroupChatWrapper extends ConsumerWidget {
  final String roomId;
  final String password;
  final bool isAdmin;
  final String? adminToken;

  const _GroupChatWrapper({
    required this.roomId,
    required this.password,
    required this.isAdmin,
    this.adminToken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = GroupChatParams(
      roomId: roomId,
      password: password,
      isAdmin: isAdmin,
      adminToken: adminToken,
    );
    final chatState = ref.watch(groupChatNotifierProvider(params));
    final l10n = AppLocalizations.of(context)!;

    switch (chatState.status) {
      case GroupChatStatus.connecting:
        return const Center(child: CircularProgressIndicator());

      case GroupChatStatus.chatting:
        return GroupChatRoomView(
          roomId: roomId,
          password: password,
          isAdmin: isAdmin,
          adminToken: adminToken,
        );

      case GroupChatStatus.destroyed:
        return _StatusView(
          icon: Icons.delete_forever,
          message: l10n.groupRoomDestroyed,
          context: context,
        );

      case GroupChatStatus.kicked:
        return _StatusView(
          icon: Icons.block,
          message: l10n.groupKicked,
          context: context,
        );

      case GroupChatStatus.error:
        return _StatusView(
          icon: Icons.error_outline,
          message: l10n.errorGeneric,
          context: context,
        );
    }
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final String message;
  final BuildContext context;

  const _StatusView({
    required this.icon,
    required this.message,
    required this.context,
  });

  @override
  Widget build(BuildContext outerContext) {
    final l10n = AppLocalizations.of(outerContext)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.glitchRed),
          const SizedBox(height: 16),
          Text(message, style: Theme.of(outerContext).textTheme.titleMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(outerContext).popUntil((r) => r.isFirst),
            child: Text(l10n.commonBack),
          ),
        ],
      ),
    );
  }
}
