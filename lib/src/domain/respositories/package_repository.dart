import 'package:cura/src/domain/models/package_info.dart';

abstract class PackageRepository {
  Future<PackageInfo> getPackageInfo(String packageName);
}
