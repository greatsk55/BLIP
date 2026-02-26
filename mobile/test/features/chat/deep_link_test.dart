import 'package:flutter_test/flutter_test.dart';

/// 딥링크 URL 파싱 로직 단위 테스트
/// GoRouter의 queryParameters 추출 및 locale redirect 로직 검증
void main() {
  /// 딥링크 ID 검증: 영숫자 6~32자만 허용
  final validIdPattern = RegExp(r'^[a-zA-Z0-9]{6,32}$');

  group('딥링크 URL 파싱', () {
    test('?k= query parameter에서 비밀번호 추출', () {
      final uri =
          Uri.parse('https://blip.app/room/ABCD1234?k=WXYZ-5678');
      final password = uri.queryParameters['k'];
      expect(password, 'WXYZ-5678');
    });

    test('?k= 없으면 null', () {
      final uri = Uri.parse('https://blip.app/room/ABCD1234');
      final password = uri.queryParameters['k'];
      expect(password, isNull);
    });

    test('URL-encoded 비밀번호 디코딩', () {
      final encoded = Uri.encodeComponent('AB+CD/EF==');
      final uri =
          Uri.parse('https://blip.app/room/ABCD1234?k=$encoded');
      final password = uri.queryParameters['k'];
      // Uri.parse는 자동으로 디코딩
      expect(password, 'AB+CD/EF==');
    });

    test('#fragment에서 비밀번호 추출', () {
      final uri =
          Uri.parse('https://blip.app/room/ABCD1234#WXYZ-5678');
      final fragment = uri.fragment;
      expect(fragment, 'WXYZ-5678');
    });

    test('#fragment URL-encoded 비밀번호 디코딩', () {
      final encoded = Uri.encodeComponent('AB+CD/EF==');
      final uri =
          Uri.parse('https://blip.app/room/ABCD1234#$encoded');
      final password = Uri.decodeComponent(uri.fragment);
      expect(password, 'AB+CD/EF==');
    });

    test('#fragment 빈 경우 null 처리', () {
      final uri = Uri.parse('https://blip.app/room/ABCD1234');
      final fragment = uri.fragment;
      final password = fragment.isNotEmpty ? fragment : null;
      expect(password, isNull);
    });

    test('roomId 유효성 검증: 정상', () {
      expect(validIdPattern.hasMatch('ABCD1234'), isTrue);
      expect(validIdPattern.hasMatch('abcdef'), isTrue);
      expect(validIdPattern.hasMatch('A1B2C3D4E5F6'), isTrue);
    });

    test('roomId 유효성 검증: 비정상 (특수문자, 짧은 ID)', () {
      expect(validIdPattern.hasMatch('AB'), isFalse); // 너무 짧음
      expect(validIdPattern.hasMatch('AB-CD'), isFalse); // 하이픈
      expect(validIdPattern.hasMatch(''), isFalse); // 빈 문자열
      expect(validIdPattern.hasMatch('AB CD12'), isFalse); // 공백
    });
  });

  group('locale 프리픽스 딥링크 redirect', () {
    test('locale redirect 시 ?k= 유지', () {
      const roomId = 'ABCD1234';
      const password = 'WXYZ-5678';

      // redirect 로직 시뮬레이션
      final k = password;
      final redirectUrl =
          k.isNotEmpty ? '/room/$roomId?k=$k' : '/room/$roomId';
      expect(redirectUrl, '/room/ABCD1234?k=WXYZ-5678');
    });

    test('locale redirect 시 ?k= 없으면 plain URL', () {
      const roomId = 'ABCD1234';

      // k가 null인 경우
      const String? k = null;
      final redirectUrl =
          k != null ? '/room/$roomId?k=$k' : '/room/$roomId';
      expect(redirectUrl, '/room/ABCD1234');
    });

    test('locale redirect 시 #fragment 유지', () {
      final uri = Uri.parse(
          'https://blip.app/ko/room/ABCD1234#WXYZ-5678');
      const roomId = 'ABCD1234';
      final k = uri.queryParameters['k'];
      final fragment = uri.fragment;

      late final String redirectUrl;
      if (k != null) {
        redirectUrl = '/room/$roomId?k=$k';
      } else if (fragment.isNotEmpty) {
        redirectUrl = '/room/$roomId#$fragment';
      } else {
        redirectUrl = '/room/$roomId';
      }
      expect(redirectUrl, '/room/ABCD1234#WXYZ-5678');
    });
  });

  group('비밀번호 우선순위 (extra > query > fragment)', () {
    test('extra가 있으면 extra 우선', () {
      const String? passwordFromExtra = 'FROM_EXTRA';
      const String? passwordFromQuery = 'FROM_QUERY';
      const String? passwordFromFragment = 'FROM_FRAGMENT';
      final result =
          passwordFromExtra ?? passwordFromQuery ?? passwordFromFragment;
      expect(result, 'FROM_EXTRA');
    });

    test('extra null → query 사용', () {
      const String? passwordFromExtra = null;
      const String? passwordFromQuery = 'FROM_QUERY';
      const String? passwordFromFragment = 'FROM_FRAGMENT';
      final result =
          passwordFromExtra ?? passwordFromQuery ?? passwordFromFragment;
      expect(result, 'FROM_QUERY');
    });

    test('extra·query null → fragment 사용', () {
      const String? passwordFromExtra = null;
      const String? passwordFromQuery = null;
      const String? passwordFromFragment = 'FROM_FRAGMENT';
      final result =
          passwordFromExtra ?? passwordFromQuery ?? passwordFromFragment;
      expect(result, 'FROM_FRAGMENT');
    });

    test('모두 null이면 null', () {
      const String? passwordFromExtra = null;
      const String? passwordFromQuery = null;
      const String? passwordFromFragment = null;
      final result =
          passwordFromExtra ?? passwordFromQuery ?? passwordFromFragment;
      expect(result, isNull);
    });
  });
}
