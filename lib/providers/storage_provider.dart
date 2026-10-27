import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import '../services/rollover_service.dart';

final storageServiceProvider = Provider<StorageService>(
  (_) => throw UnimplementedError('Override in main()'),
);

final rolloverServiceProvider = Provider<RolloverService>(
  (_) => RolloverService(),
);
