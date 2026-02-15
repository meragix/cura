/// Classe de base scellée pour forcer la gestion de tous les cas
sealed class Result<T> {
  const Result();

  /// Helpers pour faciliter la vérification rapide
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
}

/// Cas de succès : contient la donnée typée
class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

/// Cas d'échec : contient le message et l'exception optionnelle
class Failure<T> extends Result<T> {
  final String message;
  final dynamic exception;
  final StackTrace? stackTrace;

  const Failure(this.message, {this.exception, this.stackTrace});
}
