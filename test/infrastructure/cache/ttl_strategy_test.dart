import 'package:cura/src/infrastructure/cache/strategies/ttl_strategy.dart';
import 'package:test/test.dart';

void main() {
  group('TtlStrategy.getAggregatedTtl', () {
    test('returns 24h for popularity >= 90', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 90), 24);
      expect(TtlStrategy.getAggregatedTtl(popularity: 95), 24);
      expect(TtlStrategy.getAggregatedTtl(popularity: 100), 24);
    });

    test('returns defaultTtl for popularity 70-89', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 70), 12);
      expect(TtlStrategy.getAggregatedTtl(popularity: 80), 12);
      expect(TtlStrategy.getAggregatedTtl(popularity: 89), 12);
    });

    test('respects custom defaultTtl for popularity 70-89', () {
      expect(
        TtlStrategy.getAggregatedTtl(popularity: 75, defaultTtl: 6),
        6,
      );
      expect(
        TtlStrategy.getAggregatedTtl(popularity: 80, defaultTtl: 24),
        24,
      );
    });

    test('returns 6h for popularity 40-69', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 40), 6);
      expect(TtlStrategy.getAggregatedTtl(popularity: 55), 6);
      expect(TtlStrategy.getAggregatedTtl(popularity: 69), 6);
    });

    test('returns 3h for popularity < 40', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 0), 3);
      expect(TtlStrategy.getAggregatedTtl(popularity: 20), 3);
      expect(TtlStrategy.getAggregatedTtl(popularity: 39), 3);
    });

    test('boundary: popularity 90 returns 24h not defaultTtl', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 90, defaultTtl: 6), 24);
    });

    test('boundary: popularity 69 returns 6h not defaultTtl', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 69, defaultTtl: 6), 6);
    });

    test('boundary: popularity 39 returns 3h', () {
      expect(TtlStrategy.getAggregatedTtl(popularity: 39), 3);
    });
  });
}
