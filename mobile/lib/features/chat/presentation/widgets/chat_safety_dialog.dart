import 'package:flutter/material.dart';
import 'package:blip/l10n/app_localizations.dart';
import '../../../../core/crypto/crypto.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/models/message.dart';

class ChatSafetyDialog extends StatefulWidget {
  const ChatSafetyDialog({
    super.key,
    required this.roomId,
    required this.password,
    required this.messages,
    required this.onBlock,
  });
  final String roomId;
  final String password;
  final List<DecryptedMessage> messages;
  final Future<void> Function() onBlock;

  @override
  State<ChatSafetyDialog> createState() => _ChatSafetyDialogState();
}

class _ChatSafetyDialogState extends State<ChatSafetyDialog> {
  String _reason = 'harassment';
  bool _includeEvidence = false;
  bool _busy = false;
  String? _status;

  Future<void> _report() async {
    setState(() {
      _busy = true;
      _status = null;
    });
    try {
      final keys = await deriveKeysFromPasswordAsync(
        widget.password,
        widget.roomId,
      );
      final auth = hashAuthKey(keys.authKey);
      keys.dispose();
      final textMessages = widget.messages
          .where((m) => m.type == MessageType.text)
          .toList();
      await ApiClient().dio.post(
        '/api/safety/report',
        data: {
          'roomId': widget.roomId,
          'authKeyHash': auth,
          'reason': _reason,
          'includeEvidence': _includeEvidence,
          if (_includeEvidence)
            'messages': textMessages
                .skip(textMessages.length > 4 ? textMessages.length - 4 : 0)
                .map(
                  (m) => {
                    'content': m.content,
                    'senderName': m.senderName,
                    'timestamp': m.timestamp,
                  },
                )
                .toList(),
        },
      );
      if (mounted) {
        setState(() => _status = AppLocalizations.of(context)!.safetyReported);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _status = AppLocalizations.of(context)!.safetyFailed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _block() async {
    setState(() => _busy = true);
    try {
      await widget.onBlock();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = AppLocalizations.of(context)!.safetyFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final reasons = {
      'harassment': t.safetyHarassment,
      'sexual': t.safetySexual,
      'hate': t.safetyHate,
      'violence': t.safetyViolence,
      'scam': t.safetyScam,
      'other': t.safetyOther,
    };
    return AlertDialog(
      title: Text(t.safetyTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.safetyNotice),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: InputDecoration(labelText: t.safetyReason),
              items: reasons.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _reason = value!),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _includeEvidence,
              title: Text(
                t.safetyEvidence,
                style: const TextStyle(fontSize: 13),
              ),
              onChanged: _busy
                  ? null
                  : (value) =>
                        setState(() => _includeEvidence = value ?? false),
            ),
            if (_status != null)
              Semantics(liveRegion: true, child: Text(_status!)),
            const SizedBox(height: 12),
            Text(t.safetyBlockNotice, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            const SelectableText(
              'wonwookimnida@gmail.com',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(t.safetyClose),
        ),
        TextButton(
          onPressed: _busy ? null : _report,
          child: Text(t.safetyReport),
        ),
        TextButton(
          onPressed: _busy ? null : _block,
          child: Text(t.safetyBlock),
        ),
      ],
    );
  }
}
