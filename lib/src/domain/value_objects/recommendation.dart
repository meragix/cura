/// Priority level of an actionable [Recommendation].
enum RecommendationLevel {
  /// General guidance — low urgency.
  advisory,

  /// Suggested action — moderate urgency.
  action,

  /// Elevated concern — review required before production use.
  warning,

  /// Blocking concern — do not use in production without resolution.
  critical,
}

/// An actionable, typed recommendation generated from scoring signals.
///
/// Prefer using [level] to drive UI rendering (icons, colours, ordering)
/// rather than parsing [message] content.
final class Recommendation {
  const Recommendation({
    required this.level,
    required this.message,
  });

  /// Priority level that drives visual rendering and sort order.
  final RecommendationLevel level;

  /// Human-readable guidance text.
  final String message;

  @override
  String toString() => message;
}
