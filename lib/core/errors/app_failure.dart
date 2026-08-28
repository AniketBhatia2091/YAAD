/// Standardized Failure Model for Repository & Data layer operations
class AppFailure {
  final String message;
  final String? code;
  final dynamic exception;

  const AppFailure({
    required this.message,
    this.code,
    this.exception,
  });

  @override
  String toString() => 'AppFailure(message: $message, code: $code)';
}
