import 'package:app/APIService.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fetchTeamImages keeps every usable media item in API order', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/teams/971/media');
      expect(request.url.queryParameters['year'], '2026');

      return http.Response(
        '''
        {
          "media": [
            {
              "type": "cdphotothread",
              "direct_url": "https://images.example/robot-one.jpg",
              "view_url": "https://example/robot-one"
            },
            {
              "type": "imgur",
              "direct_url": "https://images.example/robot-two.jpg",
              "view_url": "https://example/robot-two"
            },
            {
              "type": "image",
              "direct_url": null,
              "view_url": "https://images.example/robot-three.jpg"
            },
            {"type": "unknown", "direct_url": null, "view_url": null}
          ]
        }
        ''',
        200,
      );
    });
    final service = APIService(baseUrl: 'https://api.example', client: client);

    final images = await service.fetchTeamImages(971);

    expect(images, hasLength(3));
    expect(images.map((image) => image['url']), [
      'https://images.example/robot-one.jpg',
      'https://images.example/robot-two.jpg',
      'https://images.example/robot-three.jpg',
    ]);
    expect(images.first['type'], 'cdphotothread');

    service.dispose();
  });

  test('fetchRobotImages builds authenticated URLs for scout photos', () async {
    final client = MockClient((request) async {
      expect(
        request.url.path,
        '/robot-images/group-1/events/2026test/teams/971',
      );
      expect(request.url.queryParameters['username'], 'scout');
      return http.Response(
        '''
        {
          "images": [
            {
              "id": "507f1f77bcf86cd799439011",
              "content_type": "image/jpeg",
              "capture_source": "camera",
              "scout": "scout",
              "created_at": "2026-09-27T12:00:00Z"
            }
          ]
        }
        ''',
        200,
      );
    });
    final service = APIService(baseUrl: 'https://api.example', client: client);

    final images = await service.fetchRobotImages(
      groupId: 'group-1',
      event: '2026test',
      team: 971,
      username: 'scout',
    );

    expect(images, hasLength(1));
    expect(images.first['source'], 'camera');
    final imageUrl = Uri.parse(images.first['url']!);
    expect(imageUrl.path, '/robot-images/507f1f77bcf86cd799439011/content');
    expect(imageUrl.queryParameters['group_id'], 'group-1');
    expect(imageUrl.queryParameters['username'], 'scout');

    service.dispose();
  });
}
