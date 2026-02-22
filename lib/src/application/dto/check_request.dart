class CheckRequest {
  final String pubspecPath;
  final bool includeDevDependencies;
  final int minScore;
  final bool failOnVulnerable;
  final bool failOnDiscontinued;
  final bool quiet;
  final bool jsonOutput;
  final List<String> ignoredPackages;

  const CheckRequest({
    required this.pubspecPath,
    required this.includeDevDependencies,
    required this.minScore,
    required this.failOnVulnerable,
    required this.failOnDiscontinued,
    required this.quiet,
    required this.jsonOutput,
    required this.ignoredPackages,
  });

  /// Create from command args
  factory CheckRequest.fromArgs({
    String? path,
    bool includeDevDeps = false,
    int minScore = 70,
    bool failOnVulnerable = true,
    bool failOnDiscontinued = true,
    bool quiet = false,
    bool json = false,
    List<String> ignored = const [],
  }) {
    return CheckRequest(
      pubspecPath: path ?? './pubspec.yaml',
      includeDevDependencies: includeDevDeps,
      minScore: minScore,
      failOnVulnerable: failOnVulnerable,
      failOnDiscontinued: failOnDiscontinued,
      quiet: quiet,
      jsonOutput: json,
      ignoredPackages: ignored,
    );
  }
}
