import 'package:blip/core/utils/chat_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Apple login preserves the complete local invitation and rejects external redirects', () {
    const invitation = '/ko/group/ABCDEF12#k=AB%2BCD%2FEF%3D%3D';
    final login = Uri(path: '/login', queryParameters: {'from': invitation});
    expect(safePostLoginPath(login.queryParameters['from']), invitation);
    for (final external in ['https://example.com', '//example.com/path', 'javascript:alert(1)', '/login?from=/room/x', '/splash']) {
      expect(safePostLoginPath(external), '/');
    }
  });
  group('shared chat invite password', () {
    test('reads the fragment emitted by the production web client', () {
      expect(
        passwordFromChatUri(
          Uri.parse(
            'https://blip-blip.vercel.app/ko/room/ABCDEF12#k=ABCD-1234',
          ),
        ),
        'ABCD-1234',
      );
    });

    test('reads creator fragments without including the admin token', () {
      expect(
        passwordFromChatUri(
          Uri.parse('/group/ABCDEF12#p=ABCD-1234&a=ADMIN-TOKEN'),
        ),
        'ABCD-1234',
      );
    });

    test('supports app query links and legacy bare fragments', () {
      expect(
        passwordFromChatUri(Uri.parse('/room/ABCDEF12?k=ABCD-1234')),
        'ABCD-1234',
      );
      expect(
        passwordFromChatUri(Uri.parse('/room/ABCDEF12#ABCD-1234')),
        'ABCD-1234',
      );
    });

    test('fragment wins over a conflicting query parameter', () {
      expect(
        passwordFromChatUri(
          Uri.parse('/room/ABCDEF12?k=OLD1-2345#k=ABCD-1234'),
        ),
        'ABCD-1234',
      );
    });

    test('decodes a password once and rejects unrelated fragments', () {
      expect(
        passwordFromChatUri(Uri.parse('/room/ABCDEF12#k=AB%2BCD%2FEF%3D%3D')),
        'AB+CD/EF==',
      );
      expect(
        passwordFromChatUri(Uri.parse('/room/ABCDEF12#other=value')),
        isNull,
      );
      expect(passwordFromChatUri(Uri.parse('/room/ABCDEF12')), isNull);
    });
  });
}
