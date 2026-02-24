

import 'package:pool/pool.dart';

/// Manager : Gestion centralisée du Pool de concurrence
/// 
/// Responsabilité :
/// - Créer et configurer le Pool
/// - Fournir des statistiques sur l'utilisation
/// - Cleanup automatique
class PoolManager {
  final Pool _pool;
  final int _maxConcurrency;
  
  // Statistics
  int _totalRequests = 0;
  int _activeRequests = 0;
  int _queuedRequests = 0;
  
  PoolManager({int maxConcurrency = 5})
      : _maxConcurrency = maxConcurrency, _pool = Pool(maxConcurrency);

  /// Execute a task with pool resource
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

  /// Get pool statistics
  PoolStats get stats => PoolStats(
        maxConcurrency:_maxConcurrency,
        activeRequests: _activeRequests,
        queuedRequests: _queuedRequests,
        totalRequests: _totalRequests,
      );

  /// Check if pool is idle (no active/queued requests)
  bool get isIdle => _activeRequests == 0 && _queuedRequests == 0;

  /// Close the pool
  Future<void> close() => _pool.close();

  /// Reset statistics
  void resetStats() {
    _totalRequests = 0;
    _activeRequests = 0;
    _queuedRequests = 0;
  }
}

/// Pool statistics
class PoolStats {
  final int maxConcurrency;
  final int activeRequests;
  final int queuedRequests;
  final int totalRequests;
  
  const PoolStats({
    required this.maxConcurrency,
    required this.activeRequests,
    required this.queuedRequests,
    required this.totalRequests,
  });
  
  /// Utilization percentage (0-100)
  double get utilization {
    if (maxConcurrency == 0) return 0;
    return (activeRequests / maxConcurrency * 100);
  }
  
  /// Check if pool is saturated (all slots used + queue)
  bool get isSaturated => activeRequests >= maxConcurrency && queuedRequests > 0;
  
  @override
  String toString() {
    return 'PoolStats(active: $activeRequests/$maxConcurrency, '
           'queued: $queuedRequests, total: $totalRequests, '
           'utilization: ${utilization.toStringAsFixed(1)}%)';
  }
}
