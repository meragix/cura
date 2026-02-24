import 'package:pool/pool.dart';

/// Centralized concurrency manager built on top of the `pool` package.
///
/// Responsibilities:
/// - Create and configure the underlying [Pool].
/// - Expose real-time utilization statistics via [stats].
/// - Release all resources cleanly on [close].
class PoolManager {
  final Pool _pool;
  final int _maxConcurrency;

  int _totalRequests = 0;
  int _activeRequests = 0;
  int _queuedRequests = 0;

  /// Creates a [PoolManager] capped at [maxConcurrency] simultaneous tasks.
  ///
  /// Defaults to 5 concurrent tasks when [maxConcurrency] is not provided.
  PoolManager({int maxConcurrency = 5})
      : _maxConcurrency = maxConcurrency,
        _pool = Pool(maxConcurrency);

  /// Queues [task] and executes it once a pool slot becomes available.
  ///
  /// Updates the [stats] counters automatically for the full lifecycle of
  /// the request (queued → active → done). The pool slot is always released
  /// after the task completes, even if it throws.
  Future<T> execute<T>(Future<T> Function() task) async {
    _totalRequests++;
    _queuedRequests++;

    return _pool.withResource(() async {
      _queuedRequests--;
      _activeRequests++;

      try {
        return await task();
      } finally {
        _activeRequests--;
      }
    });
  }

  /// An immutable snapshot of current pool utilization and request counts.
  PoolStats get stats => PoolStats(
        maxConcurrency: _maxConcurrency,
        activeRequests: _activeRequests,
        queuedRequests: _queuedRequests,
        totalRequests: _totalRequests,
      );

  /// Whether the pool has no active or queued requests.
  bool get isIdle => _activeRequests == 0 && _queuedRequests == 0;

  /// Closes the pool and releases its underlying resources.
  ///
  /// No new tasks may be submitted after this call.
  Future<void> close() => _pool.close();

  /// Resets all request counters to zero.
  ///
  /// Does not affect the running state of the pool; tasks already executing
  /// or queued continue normally.
  void resetStats() {
    _totalRequests = 0;
    _activeRequests = 0;
    _queuedRequests = 0;
  }
}

/// Immutable snapshot of [PoolManager] runtime statistics.
class PoolStats {
  /// Maximum number of tasks that may run concurrently.
  final int maxConcurrency;

  /// Number of tasks currently executing inside the pool.
  final int activeRequests;

  /// Number of tasks waiting for a free pool slot.
  final int queuedRequests;

  /// Cumulative total of all tasks submitted since creation or last [PoolManager.resetStats].
  final int totalRequests;

  /// Creates a [PoolStats] snapshot with the provided counter values.
  const PoolStats({
    required this.maxConcurrency,
    required this.activeRequests,
    required this.queuedRequests,
    required this.totalRequests,
  });

  /// Current pool utilization as a percentage (0–100).
  ///
  /// Returns `0` when [maxConcurrency] is zero to avoid division by zero.
  double get utilization {
    if (maxConcurrency == 0) return 0;
    return (activeRequests / maxConcurrency * 100);
  }

  /// Whether all pool slots are occupied **and** tasks are waiting in the queue.
  bool get isSaturated => activeRequests >= maxConcurrency && queuedRequests > 0;

  @override
  String toString() {
    return 'PoolStats(active: $activeRequests/$maxConcurrency, '
        'queued: $queuedRequests, total: $totalRequests, '
        'utilization: ${utilization.toStringAsFixed(1)}%)';
  }
}
