import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cura/src/domain/entities/package_audit_result.dart';
import 'package:cura/src/domain/usecases/check_packages_usecase.dart';
import 'package:cura/src/domain/value_objects/result.dart';
import 'package:cura/src/presentation/cli/presenters/check_presenter.dart';
import 'package:cura/src/shared/utils/pubspec_parser.dart';

class CheckCommand extends Command<int> {
  final CheckPackagesUsecase _checkUseCase;
  final CheckPresenter _presenter;
  final List<String> _ignoredPackages;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  String get name => 'check';

  @override
  String get description => 'Analize all packages in pubspec.yaml';

  CheckCommand({
    required CheckPackagesUsecase checkUseCase,
    required CheckPresenter presenter,
    List<String> ignoredPackages = const [],
  })  : _checkUseCase = checkUseCase,
        _presenter = presenter,
        _ignoredPackages = ignoredPackages {
    argParser
      ..addOption(
        'path',
        abbr: 'p',
        help: 'Path to pubspec.yaml',
        defaultsTo: './pubspec.yaml',
      )
      ..addFlag(
        'dev-dependencies',
        help: 'Include dev dependencies',
        defaultsTo: false,
      )
      ..addOption(
        'min-score',
        help: 'Minimum acceptable score',
        defaultsTo: '70',
      )
      ..addFlag(
        'fail-on-vulnerable',
        help: 'Fail if vulnerabilities found',
        defaultsTo: true,
      )
      ..addFlag(
        'fail-on-discontinued',
        help: 'Fail if discontinued packages found',
        defaultsTo: true,
      )
      ..addFlag(
        'quiet',
        abbr: 'q',
        help: 'Minimal output',
        defaultsTo: false,
      )
      ..addFlag(
        'json',
        help: 'JSON output',
        defaultsTo: false,
      );
  }

  @override
  Future<int> run() async {
    final pubspecPath = argResults!['path'] as String;
    final includeDevDeps = argResults!['dev-dependencies'] as bool;
    // final minScore = int.parse(argResults!['min-score'] as String);
    // final failOnVulnerable = argResults!['fail-on-vulnerable'] as bool;
    // final failOnDiscontinued = argResults!['fail-on-discontinued'] as bool;
    // final quiet = argResults!['quiet'] as bool;
    final jsonOutput = argResults!['json'] as bool;

    _stopwatch.start();

    // 1. Parse pubspec
    final packageNames = await _parsePubspec(
      path: pubspecPath,
      includeDevDeps: includeDevDeps,
    );

    if (packageNames.isEmpty) {
      _presenter.showError('No packages found in $pubspecPath');
      return 1;
    }

    // 2. Filter ignored packages
    final packagesToAudit = packageNames.where((name) => !_ignoredPackages.contains(name)).toList();

    // 3. Show header
    _presenter.showHeader(total: packagesToAudit.length);

    // 4. Stream audit results (collect, don't print yet)
    var processedCount = 0;
    var failureCount = 0;

    // final results = <PackageAuditResult>[];
    // final criticalPackages = <PackageAuditResult>[];
    // var processedCount = 0;
    // var completedCount = 0;
    // var failureCount = 0;
    // var cacheHits = 0;
    // var apiCalls = 0;
    // // final results = <dynamic>[]; // Pour JSON output

    final progess = _presenter.showProgess();

    await for (final result in _checkUseCase.execute(packagesToAudit)) {
      processedCount++;

      // Update progress bar
      _presenter.updateProgress(current: processedCount, total: packagesToAudit.length, progress: progess);

      switch (result) {
        case Success<PackageAuditResult>(:final value):
          _presenter.collectPackageResult(value);
        case Failure<PackageAuditResult>(:final error):
          failureCount++;
          _presenter.showPackageError(error, progess);
      }
    }

    _presenter.stopProgess(current: processedCount, total: packagesToAudit.length, progress: progess);

    // 5. Show summary
    if (jsonOutput) {
      _presenter.showJsonOutput([]);
    } else {
      _presenter.showSummary(total: packagesToAudit.length, failures: failureCount, stopwatch: _stopwatch);
    }

    return failureCount > 0 ? 1 : 0;
  }

  Future<List<String>> _parsePubspec({
    required String path,
    required bool includeDevDeps,
  }) async {
    final file = File(path);

    if (!await file.exists()) {
      throw FileSystemException('pubspec.yaml not found', path);
    }

    final pubspec = PubspecParser.parse(await file.readAsString());

    final packages = <PubDevSource>[...pubspec.auditableDeps];

    if (includeDevDeps) {
      packages.addAll(pubspec.auditableDevDeps);
    }

    return packages.map((e) => e.name).toList();
  }
}
