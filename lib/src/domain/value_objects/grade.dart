/// Letter grade derived from a composite health score (0–100).
///
/// | Grade | Score range |
/// |-------|-------------|
/// | A+    | ≥ 90        |
/// | A     | 80 – 89     |
/// | B     | 70 – 79     |
/// | C     | 60 – 69     |
/// | D     | 50 – 59     |
/// | F     | < 50        |
enum Grade {
  aPlus('A+'),
  a('A'),
  b('B'),
  c('C'),
  d('D'),
  f('F');

  const Grade(this.label);

  /// Human-readable label (e.g. `'A+'`, `'B'`).
  final String label;

  /// Derives the [Grade] for a given numeric [score] (0–100).
  static Grade fromScore(int score) => switch (score) {
        >= 90 => Grade.aPlus,
        >= 80 => Grade.a,
        >= 70 => Grade.b,
        >= 60 => Grade.c,
        >= 50 => Grade.d,
        _ => Grade.f,
      };

  @override
  String toString() => label;
}
