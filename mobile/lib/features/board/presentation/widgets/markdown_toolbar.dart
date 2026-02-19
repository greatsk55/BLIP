import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// 마크다운 편집 툴바 (8개 도구)
/// web: MarkdownToolbar.tsx 동일 도구셋
class MarkdownToolbar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;

  const MarkdownToolbar({
    super.key,
    required this.controller,
    required this.isDark,
  });

  static const _tools = [
    _ToolDef(Icons.format_bold, 'Bold', '**', '**'),
    _ToolDef(Icons.format_italic, 'Italic', '_', '_'),
    _ToolDef(Icons.code, 'Code', '`', '`'),
    _ToolDef(Icons.format_quote, 'Quote', '> ', ''),
    _ToolDef(Icons.format_list_bulleted, 'List', '- ', ''),
    _ToolDef(Icons.format_list_numbered, 'Ordered', '1. ', ''),
    _ToolDef(Icons.link, 'Link', '[', '](url)'),
    _ToolDef(Icons.horizontal_rule, 'Divider', '\n---\n', ''),
  ];

  void _applyTool(String before, String after) {
    final text = controller.text;
    final selection = controller.selection;

    // 선택 영역이 없거나 유효하지 않으면 커서 위치에 삽입
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final selected = text.substring(start, end);

    final newText =
        text.substring(0, start) + before + selected + after + text.substring(end);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: start + before.length + selected.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.ghostGreyDark : AppColors.ghostGreyLight;
    final activeColor =
        isDark ? AppColors.signalGreenDark : AppColors.signalGreenLight;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _tools.length,
        itemBuilder: (context, index) {
          final tool = _tools[index];
          return SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: () => _applyTool(tool.before, tool.after),
              icon: Icon(tool.icon, size: 18),
              color: iconColor,
              splashColor: activeColor.withValues(alpha: 0.2),
              tooltip: tool.label,
              padding: EdgeInsets.zero,
            ),
          );
        },
      ),
    );
  }
}

class _ToolDef {
  final IconData icon;
  final String label;
  final String before;
  final String after;

  const _ToolDef(this.icon, this.label, this.before, this.after);
}
