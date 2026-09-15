import 'dart:convert';

import 'package:comet/models/game_model.dart';
import 'package:comet/services/rawg_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _game = GameModel(
  id: 42,
  title: 'Test game',
  year: 2024,
  genre: 'Adventure',
  platforms: ['PC'],
  rating: 4,
  hours: 10,
  screenshots: ['https://example.com/screenshot.jpg'],
);

void main() {
  test('empty search needs neither a key nor a network request', () async {
    await http.runWithClient(() async {
      expect(await RawgApiService(apiKey: '').searchGames('   '), isEmpty);
    }, () => MockClient((_) async => throw StateError('Unexpected request')));
  });

  for (final key in ['', '   ']) {
    test(
      'unconfigured API fails before making any network requests: "$key"',
      () async {
        var requests = 0;
        await http.runWithClient(
          () async {
            final service = RawgApiService(apiKey: key);
            await expectLater(
              service.searchGames('Test'),
              throwsA(isA<RawgConfigurationException>()),
            );
            await expectLater(
              service.getGameDetails(_game),
              throwsA(isA<RawgConfigurationException>()),
            );
          },
          () => MockClient((_) async {
            requests++;
            return http.Response('{}', 200);
          }),
        );
        expect(requests, 0);
      },
    );
  }

  test('search sends the supplied key and parses valid results', () async {
    await http.runWithClient(
      () async {
        final results = await RawgApiService(
          apiKey: ' test-key ',
        ).searchGames(' Test game ');
        expect(results, hasLength(1));
        expect(results.single.id, 42);
        expect(results.single.title, 'Test game');
        expect(results.single.year, 2024);
      },
      () => MockClient((request) async {
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'api.rawg.io');
        expect(request.url.path, '/api/games');
        expect(request.url.queryParameters['key'], 'test-key');
        expect(request.url.queryParameters['search'], 'Test game');
        return http.Response(
          jsonEncode({
            'results': [
              {'id': 42, 'name': 'Test game', 'released': '2024-01-01'},
              {'id': 0, 'name': 'Invalid game'},
            ],
          }),
          200,
        );
      }),
    );
  });

  test('HTTP errors do not include the configured key', () async {
    await http.runWithClient(() async {
      await expectLater(
        RawgApiService(apiKey: 'test-private-value').searchGames('Test'),
        throwsA(
          predicate<Object>(
            (error) =>
                error.toString().contains('401') &&
                !error.toString().contains('test-private-value'),
          ),
        ),
      );
    }, () => MockClient((_) async => http.Response('{}', 401)));
  });

  test('malformed search responses produce a controlled error', () async {
    await http.runWithClient(() async {
      await expectLater(
        RawgApiService(apiKey: 'test-key').searchGames('Test'),
        throwsA(isA<Exception>()),
      );
    }, () => MockClient((_) async => http.Response('not JSON', 200)));
  });

  test(
    'details use the key on every endpoint and tolerate optional failures',
    () async {
      final paths = <String>[];
      await http.runWithClient(
        () async {
          final details = await RawgApiService(
            apiKey: 'test-key',
          ).getGameDetails(_game);
          expect(details.id, 42);
          expect(details.title, 'Updated game');
          expect(details.screenshots, _game.screenshots);
        },
        () => MockClient((request) async {
          paths.add(request.url.path);
          expect(request.url.queryParameters['key'], 'test-key');
          if (request.url.path == '/api/games/42') {
            return http.Response('{"id":42,"name":"Updated game"}', 200);
          }
          throw http.ClientException('Unavailable');
        }),
      );
      expect(
        paths,
        unorderedEquals([
          '/api/games/42',
          '/api/games/42/movies',
          '/api/games/42/screenshots',
          '/api/games/42/game-series',
        ]),
      );
    },
  );
}
