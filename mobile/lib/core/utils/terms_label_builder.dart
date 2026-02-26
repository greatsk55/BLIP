import 'package:flutter/material.dart';

import '../../features/chat/presentation/widgets/terms_dialog.dart';

/// 이용약관 동의 텍스트를 로케일 순서에 맞게 빌드하는 유틸리티 (SSOT)
///
/// [fullText] 전체 문자열 (예: "이용약관에 동의합니다")
/// [linkText] 링크로 표시할 부분 (예: "이용약관")
///
/// fullText 내에서 linkText의 위치를 찾아 prefix + link + suffix 순서로 위젯 생성.
/// 예) 한국어: "이용약관에 동의합니다" → [링크:"이용약관"] + [텍스트:"에 동의합니다"]
/// 예) 영어: "I agree to the Terms of Service" → [텍스트:"I agree to the "] + [링크:"Terms of Service"]
List<Widget> buildTermsLabel({
  required BuildContext context,
  required String fullText,
  required String linkText,
  required Color textColor,
  required Color linkColor,
  required double fontSize,
}) {
  final linkIndex = fullText.indexOf(linkText);
  if (linkIndex < 0) {
    // linkText가 fullText에 없으면 fallback
    return [
      Flexible(
        child: Text(
          fullText,
          style: TextStyle(fontSize: fontSize, color: textColor),
        ),
      ),
    ];
  }

  final prefix = fullText.substring(0, linkIndex);
  final suffix = fullText.substring(linkIndex + linkText.length);

  final linkWidget = GestureDetector(
    onTap: () => TermsDialog.show(context),
    child: Text(
      linkText,
      style: TextStyle(
        fontSize: fontSize,
        color: linkColor,
        decoration: TextDecoration.underline,
        decorationColor: linkColor,
      ),
    ),
  );

  return [
    if (prefix.isNotEmpty)
      Flexible(
        child: Text(
          prefix,
          style: TextStyle(fontSize: fontSize, color: textColor),
        ),
      ),
    linkWidget,
    if (suffix.isNotEmpty)
      Flexible(
        child: Text(
          suffix,
          style: TextStyle(fontSize: fontSize, color: textColor),
        ),
      ),
  ];
}
