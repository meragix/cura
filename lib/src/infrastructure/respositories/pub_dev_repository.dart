import 'package:cura/src/domain/models/package_info.dart';
import 'package:cura/src/domain/respositories/package_repository.dart';
import 'package:cura/src/infrastructure/api/pub_api_service.dart';

class PubDevRepository implements PackageRepository {
  final PubApiService _service;

  PubDevRepository(this._service);

  @override
  Future<PackageInfo> getPackageInfo(String packageName) async {
    return _service.getPackageInfo(packageName);
  }
}
