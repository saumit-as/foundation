import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/credentials_store.dart';
import 'network/memoria_api_client.dart';
import '../data/local/app_database.dart';
import '../data/sync/outbox_flusher.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final credentialsStoreProvider = Provider<CredentialsStore>((ref) {
  return CredentialsStore();
});

final apiClientProvider = Provider<MemoriaApiClient>((ref) {
  final store = ref.watch(credentialsStoreProvider);
  return MemoriaApiClient(credentialsStore: store);
});

final outboxFlusherProvider = Provider<OutboxFlusher>((ref) {
  final db = ref.watch(databaseProvider);
  final api = ref.watch(apiClientProvider);
  return OutboxFlusher(database: db, apiClient: api);
});
