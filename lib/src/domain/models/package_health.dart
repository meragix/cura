import 'package:cura/src/domain/models/cura_score.dart';
import 'package:cura/src/domain/models/package_info.dart';

class PackageHealth {
  final PackageInfo info;
  final CuraScore score;

  PackageHealth({
    required this.info,
    required this.score,
  });

  bool get isRecommended => score.total >= 70;
  bool get isLegacy => info.daysSinceLastRelease > 540; // 18 mois
}
