import 'package:cura/src/domain/entities/score.dart';
import 'package:cura/src/presentation/renderers/bar_renderer.dart';
import 'package:test/test.dart';

void main() {
  group('BarRenderer', () {
    test('renders score breakdown', () {
      final renderer = BarRenderer(useColors: false);

      final score = Score.vulnerable('http', vulnerabilities: []);

      final breakdown = renderer.renderScoreBreakdown(score);

      expect(breakdown, contains('Vitality'));
      expect(breakdown, contains('Tech'));
      expect(breakdown, contains('Trust'));
      expect(breakdown, contains('Maint'));
    });

    test('renders popularity dots', () {
      final renderer = BarRenderer(useColors: false);

      // 100% → ●●●
      expect(renderer.renderPopularityDots(100), '●●●');

      // 66% → ●●○
      expect(renderer.renderPopularityDots(66), '●●○');

      // 0% → ○○○
      expect(renderer.renderPopularityDots(0), '○○○');
    });

    test('renders pub score indicator', () {
      final renderer = BarRenderer(useColors: false);

      // High score → ●
      expect(renderer.renderPubScoreIndicator(130), '●');

      // Medium → ◐
      expect(renderer.renderPubScoreIndicator(100), '◐');

      // Low → ○
      expect(renderer.renderPubScoreIndicator(50), '○');
    });
  });
}
