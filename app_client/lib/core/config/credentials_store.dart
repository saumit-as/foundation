import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceCredentials {
  final int version;
  final String apiBaseUrl;
  final String cfAccessClientId;
  final String cfAccessClientSecret;
  final String deviceId;
  final String bearerKey;
  final String? ntfyUrl;
  final String? ntfyTopic;
  final String? ntfyToken;

  const DeviceCredentials({
    this.version = 1,
    required this.apiBaseUrl,
    required this.cfAccessClientId,
    required this.cfAccessClientSecret,
    required this.deviceId,
    required this.bearerKey,
    this.ntfyUrl,
    this.ntfyTopic,
    this.ntfyToken,
  });

  factory DeviceCredentials.fromJson(Map<String, dynamic> json) {
    return DeviceCredentials(
      version: json['v'] as int? ?? 1,
      apiBaseUrl: (json['api_base_url'] as String? ?? '').replaceAll(RegExp(r'/+$'), ''),
      cfAccessClientId: json['cf_access_client_id'] as String? ?? '',
      cfAccessClientSecret: json['cf_access_client_secret'] as String? ?? '',
      deviceId: json['device_id'] as String? ?? '',
      bearerKey: json['bearer_key'] as String? ?? '',
      ntfyUrl: json['ntfy_url'] as String?,
      ntfyTopic: json['ntfy_topic'] as String?,
      ntfyToken: json['ntfy_token'] as String?,
    );
  }

  factory DeviceCredentials.fromQrString(String qrPayload) {
    final Map<String, dynamic> map = jsonDecode(qrPayload.trim()) as Map<String, dynamic>;
    return DeviceCredentials.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'api_base_url': apiBaseUrl,
      'cf_access_client_id': cfAccessClientId,
      'cf_access_client_secret': cfAccessClientSecret,
      'device_id': deviceId,
      'bearer_key': bearerKey,
      if (ntfyUrl != null) 'ntfy_url': ntfyUrl,
      if (ntfyTopic != null) 'ntfy_topic': ntfyTopic,
      if (ntfyToken != null) 'ntfy_token': ntfyToken,
    };
  }

  bool get isValid =>
      apiBaseUrl.isNotEmpty && deviceId.isNotEmpty && bearerKey.isNotEmpty;
}

class CredentialsStore {
  static const _storageKey = 'memoria_device_credentials';
  final FlutterSecureStorage _storage;

  CredentialsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveCredentials(DeviceCredentials creds) async {
    final jsonStr = jsonEncode(creds.toJson());
    await _storage.write(key: _storageKey, value: jsonStr);
  }

  Future<DeviceCredentials?> getCredentials() async {
    final jsonStr = await _storage.read(key: _storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DeviceCredentials.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasCredentials() async {
    final creds = await getCredentials();
    return creds != null && creds.isValid;
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _storageKey);
  }
}
