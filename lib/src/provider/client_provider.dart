import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';

/// All clients. Re-fetched whenever invalidated.
final clientsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => DatabaseHelper.instance.getAllClients(),
);
