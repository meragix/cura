import 'package:cura/src/domain/entities/vulnerability.dart';
import 'package:cura/src/shared/constants/api_constants.dart';
import 'package:dio/dio.dart';

/// HTTP Client for OSV.dev API
/// 
/// Doc : https://google.github.io/osv.dev/api/
class OsvApiClient {
  final Dio _dio;

  OsvApiClient(this._dio);

  /// Query vulnerabilities for a Pub package
  ///
  /// Endpoint : POST /v1/query
  Future<List<Vulnerability>> queryVulnerabilities(String packageName) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.osvApiUrl}/v1/query',
        data: {
          'package': {
            'name': packageName,
            'ecosystem': 'Pub', // Important : spécifier Pub ecosystem
          },
        },
      );

      if (response.statusCode != 200) {
        throw Exception('OSV API error: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final vulns = data['vulns'] as List<dynamic>? ?? [];

      return vulns.map((v) => _mapToEntity(v as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception('OSV API error: ${e.message}');
    }
  }

  Vulnerability _mapToEntity(Map<String, dynamic> json) {
    return Vulnerability(
      id: json['id'] as String,
      summary: json['summary'] as String? ?? '',
      details: json['details'] as String? ?? '',
      severity: _parseSeverity(json['severity']),
      published: DateTime.parse(json['published'] as String),
      modified: json['modified'] != null ? DateTime.parse(json['modified'] as String) : null,
      affectedVersions: _parseAffectedVersions(json['affected']),
      fixedVersion: _parseFixedVersion(json['affected']),
      references: _parseReferences(json['references']),
    );
  }

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

  List<String> _parseReferences(dynamic references) {
    if (references is! List) return [];
    return references.map((ref) => ref['url'] as String?).whereType<String>().toList();
  }
}
