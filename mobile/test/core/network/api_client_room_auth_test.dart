import 'package:blip/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(
    () => dotenv.testLoad(fileInput: 'API_BASE_URL=https://blip.example'),
  );

  test(
    'room state, leave and destroy send the derived authorization value',
    () async {
      final api = ApiClient();
      final requests = <RequestOptions>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            requests.add(request);
            handler.resolve(
              Response(requestOptions: request, data: {'ok': true}),
            );
          },
        ),
      );
      await api.updateParticipantCount(
        'ABCDEF12',
        2,
        authKeyHash: 'derived-auth',
      );
      await api.leaveRoom('ABCDEF12', authKeyHash: 'derived-auth');
      await api.destroyRoom('ABCDEF12', authKeyHash: 'derived-auth');
      expect(requests.map((r) => r.path), [
        '/api/room/participant',
        '/api/room/leave',
        '/api/room/destroy',
      ]);
      for (final request in requests) {
        expect(request.data['roomId'], 'ABCDEF12');
        expect(request.data['authKeyHash'], 'derived-auth');
      }
      expect(requests.first.data['count'], 2);
    },
  );
}
