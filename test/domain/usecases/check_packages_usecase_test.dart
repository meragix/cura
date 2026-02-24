import 'package:cura/src/domain/ports/package_data_aggregator.dart';
import 'package:mocktail/mocktail.dart';

class MockPackageDataAggregator extends Mock implements PackageDataAggregator {}

void main() {
  // Tests are pending a full rewrite to match the current aggregator-based API.
  // See CheckPackagesUsecase and PackageDataAggregator for the updated contracts.
}
