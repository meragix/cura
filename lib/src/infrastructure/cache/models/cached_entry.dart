/// A generic, immutable cache envelope that associates a typed payload [T]
/// with its storage key, insertion timestamp, and time-to-live policy.
///
/// Expiry evaluation is always performed against `DateTime.now()` at the
/// call site, so [isExpired] and [timeRemaining] reflect the state at the
/// moment they are accessed rather than when the entry was created.
///
/// ### Serialization
/// [toJson] and [fromJson] are deliberately generic: callers provide the
/// type-specific `toJsonT` / `fromJsonT` functions so that [CachedEntry]
/// itself remains free of any concrete dependency.
class CachedEntry<T> {
  /// Unique identifier for this cache entry, typically the package name.
  final String key;

  /// The cached payload.
  final T data;

  /// The UTC instant at which this entry was written to the cache.
  final DateTime cachedAt;

  /// How long (in hours) this entry remains valid after [cachedAt].
  final int ttlHours;

  /// Creates a [CachedEntry] with the supplied values.
  const CachedEntry({
    required this.key,
    required this.data,
    required this.cachedAt,
    required this.ttlHours,
  });

  /// Whether this entry's TTL has elapsed.
  ///
  /// Returns `true` when `now` is after `cachedAt + ttlHours`.
  bool get isExpired {
    final expiresAt = cachedAt.add(Duration(hours: ttlHours));
    return DateTime.now().isAfter(expiresAt);
  }

  /// Time remaining until this entry expires.
  ///
  /// Returns a **negative** [Duration] when the entry is already expired.
  /// Callers should check [isExpired] first when a non-negative value is
  /// required.
  Duration get timeRemaining {
    final expiresAt = cachedAt.add(Duration(hours: ttlHours));
    return expiresAt.difference(DateTime.now());
  }

  /// How long ago this entry was written to the cache.
  Duration get age => DateTime.now().difference(cachedAt);

  /// Serialises this entry to a JSON-compatible [Map].
  ///
  /// [toJsonT] must convert the payload [data] to a JSON-serialisable value
  /// (typically a `Map<String, dynamic>` or a primitive).
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) {
    return {
      'key': key,
      'data': toJsonT(data),
      'cachedAt': cachedAt.toIso8601String(),
      'ttlHours': ttlHours,
    };
  }

  /// Deserialises a [CachedEntry] from a JSON [Map].
  ///
  /// [fromJsonT] must reconstruct the payload [T] from the raw JSON value
  /// stored under the `data` key.
  factory CachedEntry.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return CachedEntry<T>(
      key: json['key'] as String,
      data: fromJsonT(json['data']),
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      ttlHours: json['ttlHours'] as int,
    );
  }
}
