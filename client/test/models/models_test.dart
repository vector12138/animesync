import 'package:flutter_test/flutter_test.dart';
import 'package:animesync/models/models.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson 解析成功响应', () {
      final json = {'code': 200, 'message': 'ok', 'data': {'key': 'value'}};
      final response = ApiResponse.fromJson(json, (d) => d as Map<String, dynamic>);
      expect(response.code, 200);
      expect(response.message, 'ok');
      expect(response.data, {'key': 'value'});
    });

    test('fromJson 解析无 data 响应', () {
      final json = {'code': 404, 'message': 'not found'};
      final response = ApiResponse.fromJson(json, null);
      expect(response.code, 404);
      expect(response.message, 'not found');
      expect(response.data, isNull);
    });
  });

  group('AuthData', () {
    test('fromJson 解析正常数据', () {
      final json = {
        'access_token': 'abc123',
        'token_type': 'bearer',
        'user': {'id': 1, 'username': 'testuser', 'created_at': '2024-01-01'}
      };
      final auth = AuthData.fromJson(json);
      expect(auth.accessToken, 'abc123');
      expect(auth.tokenType, 'bearer');
      expect(auth.user.id, 1);
      expect(auth.user.username, 'testuser');
    });

    test('token_type 默认为 bearer', () {
      final json = {
        'access_token': 'token',
        'user': {'id': 2, 'username': 'user'}
      };
      final auth = AuthData.fromJson(json);
      expect(auth.tokenType, 'bearer');
    });
  });

  group('UserInfo', () {
    test('fromJson 解析完整数据', () {
      final json = {'id': 10, 'username': 'alice', 'created_at': '2024-02-02'};
      final user = UserInfo.fromJson(json);
      expect(user.id, 10);
      expect(user.username, 'alice');
      expect(user.createdAt, '2024-02-02');
    });

    test('fromJson 解析最小数据', () {
      final json = {'id': 5, 'username': 'bob'};
      final user = UserInfo.fromJson(json);
      expect(user.id, 5);
      expect(user.username, 'bob');
      expect(user.createdAt, isNull);
    });
  });

  group('AnimeProgress', () {
    test('fromJson 解析完整数据', () {
      final json = {
        'id': 100,
        'title': 'Test Anime',
        'cover_url': 'https://example.com/cover.jpg',
        'total_episodes': 24,
        'watched_episodes': 12,
        'status': 'watching',
        'rating': 8,
        'notes': 'Great!',
        'created_at': '2024-01-01',
        'updated_at': '2024-01-02'
      };
      final progress = AnimeProgress.fromJson(json);
      expect(progress.id, 100);
      expect(progress.title, 'Test Anime');
      expect(progress.coverUrl, 'https://example.com/cover.jpg');
      expect(progress.totalEpisodes, 24);
      expect(progress.watchedEpisodes, 12);
      expect(progress.status, 'watching');
      expect(progress.rating, 8);
      expect(progress.notes, 'Great!');
    });

    test('fromJson 使用默认值处理缺失字段', () {
      final json = {
        'id': 1,
        'title': 'Minimal',
        'watched_episodes': 5,
      };
      final progress = AnimeProgress.fromJson(json);
      expect(progress.watchedEpisodes, 5);
      expect(progress.status, 'watching'); // 默认值
      expect(progress.rating, isNull);
      expect(progress.totalEpisodes, isNull);
    });

    test('progress getter 计算正确', () {
      final progress = AnimeProgress(
        id: 1,
        title: 'Test',
        totalEpisodes: 10,
        watchedEpisodes: 5,
        status: 'watching',
      );
      expect(progress.progress, 0.5);
    });

    test('progress = 0 当 totalEpisodes 为 null', () {
      final progress = AnimeProgress(
        id: 1,
        title: 'Test',
        watchedEpisodes: 5,
        status: 'watching',
      );
      expect(progress.progress, 0.0);
    });

    test('episodeText 完整显示', () {
      final progress = AnimeProgress(
        id: 1,
        title: 'Test',
        totalEpisodes: 12,
        watchedEpisodes: 3,
        status: 'watching',
      );
      expect(progress.episodeText, '3/12');
    });

    test('episodeText 无 totalEpisodes', () {
      final progress = AnimeProgress(
        id: 1,
        title: 'Test',
        watchedEpisodes: 7,
        status: 'completed',
      );
      expect(progress.episodeText, '7 集');
    });

    test('toCreateJson 生成正确的创建数据', () {
      final progress = AnimeProgress(
        id: 1,
        title: 'New Anime',
        totalEpisodes: 13,
        watchedEpisodes: 1,
        status: 'plan_to_watch',
        rating: 9,
        notes: 'Note',
      );
      final json = progress.toCreateJson();
      expect(json['title'], 'New Anime');
      expect(json['total_episodes'], 13);
      expect(json['watched_episodes'], 1);
      expect(json['status'], 'plan_to_watch');
      expect(json['rating'], 9);
      expect(json['notes'], 'Note');
      expect(json.containsKey('id'), isFalse);
    });

    test('toUpdateJson 生成正确的更新数据', () {
      final progress = AnimeProgress(
        id: 1,
        title: 'Update Anime',
        totalEpisodes: 26,
        watchedEpisodes: 10,
        status: 'on_hold',
        rating: 7,
        notes: '',
      );
      final json = progress.toUpdateJson();
      expect(json['title'], 'Update Anime');
      expect(json['total_episodes'], 26);
      expect(json['watched_episodes'], 10);
      expect(json['status'], 'on_hold');
    });

    test('statusLabel 返回正确的中文标签', () {
      expect(AnimeProgress.statusLabel('watching'), '在看');
      expect(AnimeProgress.statusLabel('completed'), '已看完');
      expect(AnimeProgress.statusLabel('plan_to_watch'), '想看');
      expect(AnimeProgress.statusLabel('on_hold'), '搁置');
      expect(AnimeProgress.statusLabel('dropped'), '弃番');
      expect(AnimeProgress.statusLabel('unknown'), 'unknown');
    });

    test('allStatuses 包含所有状态', () {
      expect(AnimeProgress.allStatuses, [
        'watching',
        'completed',
        'plan_to_watch',
        'on_hold',
        'dropped',
      ]);
    });
  });
}
