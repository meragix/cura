import 'package:cura/src/domain/entities/package_audit_result.dart';

/// DTO : Response pour ViewCommand
class ViewResponse {
  final PackageAuditResult audit;
  // final List<DynamicSuggestion>? suggestions;

  const ViewResponse({
    required this.audit,
    // this.suggestions,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      //'package': audit.toJson(),
      //'suggestions': suggestions?.map((s) => s.toJson()).toList(),
    };
  }
}
