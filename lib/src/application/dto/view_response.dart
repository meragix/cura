import 'package:cura/src/domain/entities/package_audit_result.dart';

/// DTO : Response pour ViewCommand
class ViewResponse {
  final PackageAuditResult audit;
  // final List<DynamicSuggestion>? suggestions;

  const ViewResponse({
    required this.audit,
    // this.suggestions,
  });

  /// Serialises this response to a JSON-compatible map.
  Map<String, dynamic> toJson() => audit.toJson();
}
