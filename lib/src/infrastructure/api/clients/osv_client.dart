import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/domain/value_objects/exception.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:dio/dio.dart';

/// HTTP client for the OSV.dev vulnerability database API.
///
/// OSV (Open Source Vulnerabilities) is a distributed, open vulnerability
/// database maintained by Google. This client uses the batch-query endpoint
/// to look up advisories that affect packages published on the `Pub` ecosystem.
///
/// API reference: https://google.github.io/osv.dev/api/
///
/// ### Error handling
/// Non-200 responses and network errors are converted to [NetworkException]
/// and propagated to the caller. [MultiApiAggregator] catches them and
/// degrades gracefully to an empty vulnerability list so a temporary OSV
/// outage never blocks an audit run.
///
/// ### Known limitation — severity classification
/// The OSV `severity` array carries CVSS vector strings
/// (e.g. `CVSS:3.1/AV:N/AC:L/…`), not text labels. Computing a CVSS base
/// score from a vector requires a full CVSS calculator, which is not yet
/// implemented. As a result [Vulnerability.severity] currently defaults to
/// [VulnerabilitySeverity.unknown] for most entries. Accurate severity
/// classification is tracked as a future enhancement.
class OsvApiClient {
  final Dio _dio;

  /// Creates an [OsvApiClient] backed by [dio].
  OsvApiClient(this._dio);

  /// Queries OSV.dev for all known advisories affecting [packageName] on Pub.
  ///
  /// Sends `POST /v1/query` with the `Pub` ecosystem specifier. Returns a
  /// list of [Vulnerability] objects parsed from the response; an empty list
  /// means no advisories were found.
  ///
  /// Throws [NetworkException] on non-200 responses or connectivity failures.
  Future<List<Vulnerability>> queryVulnerabilities(String packageName) async {
    const endpoint = '${ApiConstants.osvApiUrl}/v1/query';

    try {
      final response = await _dio.post(
        endpoint,
        data: {
          'package': {
            'name': packageName,
            // The ecosystem must be 'Pub' (case-sensitive) to scope results
            // to the Dart / Flutter package registry.
            'ecosystem': 'Pub',
          },
        },
      );

      if (response.statusCode != 200) {
        throw NetworkException(
          'OSV API returned status ${response.statusCode}',
          url: endpoint,
          statusCode: response.statusCode,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final vulns = data['vulns'] as List<dynamic>? ?? [];

      return vulns
          .map((v) => _mapToEntity(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw NetworkException(
        'OSV request failed: ${e.message}',
        url: endpoint,
        originalError: e,
      );
    }
  }

  /// Maps a raw OSV advisory JSON object to a [Vulnerability] domain entity.
  Vulnerability _mapToEntity(Map<String, dynamic> json) {
    return Vulnerability(
      id: json['id'] as String,
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String? ?? '',
      severity: _parseSeverity(json['severity']),
      published: DateTime.parse(json['published'] as String),
      modified: json['modified'] != null
          ? DateTime.parse(json['modified'] as String)
          : null,
      affectedVersions: _parseAffectedVersions(json['affected']),
      fixedVersion: _parseFixedVersion(json['affected']),
      references: _parseReferences(json['references']),
    );
  }

  /// Parses the OSV `severity` array into a [VulnerabilitySeverity].
  ///
  /// OSV entries carry CVSS vector strings (e.g. `CVSS:3.1/AV:N/…`) rather
  /// than plain text levels. [VulnerabilitySeverity.fromString] is attempted
  /// first; entries that use CVSS vectors will not match and fall through to
  /// [VulnerabilitySeverity.unknown]. See the class-level note for the
  /// planned fix.
  VulnerabilitySeverity _parseSeverity(dynamic severity) {
    if (severity is List && severity.isNotEmpty) {
      final first = severity.first as Map<String, dynamic>;
      final score = first['score'] as String?;
      if (score != null) {
        return VulnerabilitySeverity.fromString(score);
      }
    }
    return VulnerabilitySeverity.unknown;
  }

  /// Extracts the list of version strings where the vulnerability was
  /// introduced from the OSV `affected[*].ranges[*].events` structure.
  ///
  /// Returns an empty list when the `affected` field is absent or
  /// does not conform to the expected shape.
  List<String> _parseAffectedVersions(dynamic affected) {
    if (affected is! List) return [];

    final versions = <String>[];
    for (final item in affected) {
      final ranges = item['ranges'] as List?;
      if (ranges != null) {
        for (final range in ranges) {
          final events = range['events'] as List?;
          if (events != null) {
            for (final event in events) {
              if (event['introduced'] != null) {
                versions.add(event['introduced'] as String);
              }
            }
          }
        }
      }
    }
    return versions;
  }

  /// Extracts the first `fixed` version string from the OSV
  /// `affected[*].ranges[*].events` structure.
  ///
  /// Returns `null` when no fix has been released or the field is absent.
  String? _parseFixedVersion(dynamic affected) {
    if (affected is! List) return null;

    for (final item in affected) {
      final ranges = item['ranges'] as List?;
      if (ranges != null) {
        for (final range in ranges) {
          final events = range['events'] as List?;
          if (events != null) {
            for (final event in events) {
              if (event['fixed'] != null) {
                return event['fixed'] as String;
              }
            }
          }
        }
      }
    }
    return null;
  }

  /// Extracts the list of advisory reference URLs from the OSV
  /// `references` array.
  ///
  /// Entries without a `url` field are silently skipped.
  List<String> _parseReferences(dynamic references) {
    if (references is! List) return [];
    return references
        .map((ref) => ref['url'] as String?)
        .whereType<String>()
        .toList();
  }
}
