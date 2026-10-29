import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../config/credentials_store.dart';

class MemoriaApiClient {
  final Dio dio;
  final CredentialsStore credentialsStore;

  MemoriaApiClient({
    Dio? dio,
    CredentialsStore? credentialsStore,
  })  : dio = dio ?? Dio(),
        credentialsStore = credentialsStore ?? CredentialsStore() {
    this.dio.options.connectTimeout = const Duration(seconds: 15);
    this.dio.options.receiveTimeout = const Duration(seconds: 30);
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final creds = await this.credentialsStore.getCredentials();
          if (creds != null && creds.isValid) {
            options.headers['Authorization'] = 'Bearer ${creds.bearerKey}';
            options.headers['X-Client-Device-Id'] = creds.deviceId;
            if (creds.cfAccessClientId.isNotEmpty) {
              options.headers['CF-Access-Client-Id'] = creds.cfAccessClientId;
            }
            if (creds.cfAccessClientSecret.isNotEmpty) {
              options.headers['CF-Access-Client-Secret'] = creds.cfAccessClientSecret;
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<String> _getBaseUrl() async {
    final creds = await credentialsStore.getCredentials();
    if (creds == null || creds.apiBaseUrl.isEmpty) {
      throw StateError('MemoriaApiClient: Device credentials not configured');
    }
    return creds.apiBaseUrl;
  }

  Future<Response<dynamic>> sendCapture(Map<String, dynamic> capture) async {
    final baseUrl = await _getBaseUrl();
    return await dio.post(
      '$baseUrl/api/v1/capture',
      data: capture,
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<Response<dynamic>> sendCaptureBatch(List<Map<String, dynamic>> captures) async {
    final baseUrl = await _getBaseUrl();
    return await dio.post(
      '$baseUrl/api/v1/capture/batch',
      data: {'captures': captures},
      options: Options(contentType: Headers.jsonContentType),
    );
  }

  Future<Response<dynamic>> uploadMedia({
    required String captureId,
    required String filePath,
    required String mediaKind,
    String? assetId,
    int? softTokenBudget,
    String? sha256Checksum,
  }) async {
    final baseUrl = await _getBaseUrl();
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final checksum = sha256Checksum ?? sha256.convert(bytes).toString();
    final realAssetId = assetId ?? const Uuid().v7();
    final budget = softTokenBudget ?? (mediaKind == 'book_page' ? 1120 : 280);

    final formData = FormData.fromMap({
      'asset_id': realAssetId,
      'media_kind': mediaKind,
      'soft_token_budget': budget,
      'sha256_checksum': checksum,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: file.uri.pathSegments.last,
      ),
    });

    return await dio.post(
      '$baseUrl/api/v1/capture/$captureId/media',
      data: formData,
    );
  }

  Future<Map<String, dynamic>> getSyncDelta(int sinceVersion, {int limit = 200}) async {
    final baseUrl = await _getBaseUrl();
    final resp = await dio.get(
      '$baseUrl/api/v1/sync/delta',
      queryParameters: {
        'since_version': sinceVersion,
        'limit': limit,
      },
    );
    if (resp.data is Map<String, dynamic>) {
      return resp.data as Map<String, dynamic>;
    }
    return jsonDecode(resp.data.toString()) as Map<String, dynamic>;
  }

  Future<Response<dynamic>> addAnnotation({
    required String captureId,
    required String content,
    String? annotationId,
  }) async {
    final baseUrl = await _getBaseUrl();
    return await dio.post(
      '$baseUrl/api/v1/captures/$captureId/annotations',
      data: {
        if (annotationId != null) 'id': annotationId,
        'content': content,
      },
    );
  }

  Future<Response<dynamic>> ackReminder(String reminderId, {DateTime? snoozedUntil}) async {
    final baseUrl = await _getBaseUrl();
    return await dio.patch(
      '$baseUrl/api/v1/reminders/$reminderId/ack',
      data: {
        'is_acknowledged': snoozedUntil == null,
        if (snoozedUntil != null) 'snoozed_until': snoozedUntil.toIso8601String(),
      },
    );
  }

  Future<Response<dynamic>> sendTriageDecision({
    required String entityId,
    required String decision,
    String targetTable = 'captures',
  }) async {
    final baseUrl = await _getBaseUrl();
    return await dio.post(
      '$baseUrl/api/v1/triage/$entityId/decision',
      data: {
        'decision': decision,
        'target_table': targetTable,
      },
    );
  }

  Future<Response<dynamic>> startReadingSession({
    required String title,
    String? author,
    List<String>? defaultTags,
    String? sessionId,
  }) async {
    final baseUrl = await _getBaseUrl();
    return await dio.post(
      '$baseUrl/api/v1/reading-sessions',
      data: {
        if (sessionId != null) 'id': sessionId,
        'source_title': title,
        if (author != null) 'author': author,
        if (defaultTags != null) 'default_tags': defaultTags,
      },
    );
  }
}
