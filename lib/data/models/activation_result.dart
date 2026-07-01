class ActivationResult {
  final bool success;
  final String? errorMessage;
  final String? typeAbonnement;

  const ActivationResult({
    required this.success,
    this.errorMessage,
    this.typeAbonnement,
  });
}
