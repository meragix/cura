/// Rate Limiter : Token Bucket Algorithm
///
/// Limite le nombre de requêtes par unité de temps.
///
/// Example:
/// ```dart
/// final limiter = RateLimiter(maxTokens: 100, refillRate: 100);
/// await limiter.acquire(); // Consomme 1 token
/// ```
class RateLimiter {
  final int _maxTokens;
  final int _refillRate; // tokens per minute
  final Duration _refillInterval;

  double _tokens;
  DateTime _lastRefill;

  RateLimiter({
    required int maxTokens,
    required int refillRate,
    Duration? refillInterval,
  })  : _maxTokens = maxTokens,
        _refillRate = refillRate,
        _refillInterval = refillInterval ?? Duration(minutes: 1),
        _tokens = maxTokens.toDouble(),
        _lastRefill = DateTime.now();

  /// Acquire a token (blocking if not available)
  Future<void> acquire({int tokens = 1}) async {
    while (true) {
      _refillTokens();

      if (_tokens >= tokens) {
        _tokens -= tokens;
        return;
      }

      // Wait before retry
      final waitTime = _calculateWaitTime(tokens);
      await Future.delayed(waitTime);
    }
  }

  /// Try to acquire without blocking
  bool tryAcquire({int tokens = 1}) {
    _refillTokens();

    if (_tokens >= tokens) {
      _tokens -= tokens;
      return true;
    }

    return false;
  }

  /// Refill tokens based on elapsed time
  void _refillTokens() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);

    if (elapsed >= _refillInterval) {
      final intervalsElapsed = elapsed.inMilliseconds / _refillInterval.inMilliseconds;

      final tokensToAdd = intervalsElapsed * _refillRate;
      _tokens = (_tokens + tokensToAdd).clamp(0, _maxTokens.toDouble());

      _lastRefill = now;
    }
  }

  /// Calculate wait time for next token availability
  Duration _calculateWaitTime(int tokensNeeded) {
    final tokensShort = tokensNeeded - _tokens;
    final intervalsNeeded = tokensShort / _refillRate;

    final millisToWait = (intervalsNeeded * _refillInterval.inMilliseconds).ceil();

    return Duration(milliseconds: millisToWait);
  }

  /// Get current token count
  double get availableTokens {
    _refillTokens();
    return _tokens;
  }

  /// Reset to full capacity
  void reset() {
    _tokens = _maxTokens.toDouble();
    _lastRefill = DateTime.now();
  }
}
