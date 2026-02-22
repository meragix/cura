class ViewRequest {
  final String packageName;
  final bool verbose;
  final bool showSuggestions;

  const ViewRequest({
    required this.packageName,
    required this.verbose,
    required this.showSuggestions,
  });

  /// Create from command args
  factory ViewRequest.fromArgs({
    required String packageName,
    bool verbose = false,
    bool suggestions = true,
  }) {
    return ViewRequest(
      packageName: packageName,
      verbose: verbose,
      showSuggestions: suggestions,
    );
  }
}
