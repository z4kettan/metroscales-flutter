import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';
import '../services/catalog_service.dart';
import '../services/report_service.dart';
import '../services/scale_service.dart';
import '../services/stock_service.dart';
import '../services/token_service.dart';
import '../services/user_service.dart';

final tokenServiceProvider = Provider((ref) => TokenService());
final apiClientProvider = Provider((ref) => ApiClient(tokens: ref.watch(tokenServiceProvider)));

final authServiceProvider =
    Provider((ref) => AuthService(ref.watch(apiClientProvider), ref.watch(tokenServiceProvider)));
final branchServiceProvider = Provider((ref) => BranchService(ref.watch(apiClientProvider)));
final catalogServiceProvider = Provider((ref) => CatalogService(ref.watch(apiClientProvider)));
final scaleServiceProvider = Provider((ref) => ScaleService(ref.watch(apiClientProvider)));
final stockServiceProvider = Provider((ref) => StockService(ref.watch(apiClientProvider)));
final reportServiceProvider = Provider((ref) => ReportService(ref.watch(apiClientProvider)));
final userServiceProvider = Provider((ref) => UserService(ref.watch(apiClientProvider)));
