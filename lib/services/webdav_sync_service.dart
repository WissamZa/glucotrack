// WebDAV backup sync — developer-registration-free cloud sync.
//
// Why WebDAV instead of Google Drive: the user supplies THEIR OWN server
// (self-hosted Nextcloud, Koofr, Synology, any standard WebDAV host), so no
// OAuth client registration with a provider is required. Combined with
// BackupCrypto the uploaded file is ciphertext — the server sees nothing
// readable. Basic auth over HTTPS (or HTTP for trusted LAN setups).
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../utils/backup_crypto.dart';

class WebDavConfig {
  final String
  url; // collection URL, e.g. https://cloud.example.com/.../glucotrack/
  final String username;
  final String password;
  final bool encrypt;
  final String passphrase;

  const WebDavConfig({
    required this.url,
    required this.username,
    required this.password,
    this.encrypt = true,
    this.passphrase = '',
  });

  /// Normalized base URL without a trailing slash.
  String get baseUrl => url.trim().replaceAll(RegExp(r'/+$'), '');

  String get plainFileName => 'glucotrack_backup.json';
  String get encryptedFileName => 'glucotrack_backup.bin';

  /// Configuration ready for sync (URL + username present, and a passphrase
  /// when encryption is on).
  bool get isComplete =>
      baseUrl.startsWith('http') &&
      username.isNotEmpty &&
      (!encrypt || passphrase.isNotEmpty);

  Map<String, dynamic> toMap() => {
    'url': url,
    'username': username,
    'password': password,
    'encrypt': encrypt ? 1 : 0,
    'passphrase': passphrase,
  };

  static WebDavConfig fromMap(Map<String, dynamic> m) => WebDavConfig(
    url: (m['url'] as String?) ?? '',
    username: (m['username'] as String?) ?? '',
    password: (m['password'] as String?) ?? '',
    encrypt: (m['encrypt'] as int? ?? 1) == 1,
    passphrase: (m['passphrase'] as String?) ?? '',
  );
}

/// Result of a sync operation.
class WebDavSyncResult {
  final bool success;
  final String? errorCode;
  final DateTime? syncedAt;

  const WebDavSyncResult.success(this.syncedAt)
    : success = true,
      errorCode = null;
  const WebDavSyncResult.failure(this.errorCode)
    : success = false,
      syncedAt = null;
}

class WebDavSyncService {
  static final WebDavSyncService _instance = WebDavSyncService._internal();
  factory WebDavSyncService() => _instance;
  WebDavSyncService._internal();

  // Credentials live in secure storage (Android Keystore / iOS Keychain),
  // never in the app database or plain preferences.
  static const _configKey = 'webdav_config';
  static const _lastSyncKey = 'webdav_last_sync';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  http.Client _client(WebDavConfig c) =>
      _BasicAuthClient(c.username, c.password);

  // ── Config persistence ────────────────────────────────────────────────
  Future<WebDavConfig?> loadConfig() async {
    final raw = await _storage.read(key: _configKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return WebDavConfig.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  Future<void> saveConfig(WebDavConfig c) =>
      _storage.write(key: _configKey, value: jsonEncode(c.toMap()));

  Future<void> clearConfig() async {
    await _storage.delete(key: _configKey);
    await _storage.delete(key: _lastSyncKey);
  }

  Future<DateTime?> lastSyncTime() async {
    final raw = await _storage.read(key: _lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  // ── Operations ────────────────────────────────────────────────────────

  /// PROPFIND depth-0 sanity check. Returns null on success, otherwise an
  /// error code suitable for localization: 'unauthorized' | 'not_found' |
  /// 'invalid_url' | 'http_{code}'.
  Future<String?> testConnection(WebDavConfig c) async {
    if (Uri.tryParse(c.baseUrl) == null || !c.baseUrl.startsWith('http')) {
      return 'invalid_url';
    }
    try {
      final response = await _client(c)
          .send(
            http.Request('PROPFIND', Uri.parse(c.baseUrl))
              ..headers['Depth'] = '0',
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 207 || response.statusCode == 200) return null;
      if (response.statusCode == 401 || response.statusCode == 403) {
        return 'unauthorized';
      }
      if (response.statusCode == 404) return 'not_found';
      return 'http_${response.statusCode}';
    } on Exception catch (e) {
      return e.toString().contains('TimeoutException') ? 'timeout' : 'network';
    }
  }

  /// Uploads the backup JSON (encrypted when [WebDavConfig.encrypt]).
  /// Keeps a single fixed file per mode — no duplicate backups accumulate.
  Future<WebDavSyncResult> uploadBackup(WebDavConfig c, String json) async {
    if (!c.isComplete) return const WebDavSyncResult.failure('incomplete');
    try {
      final fileName = c.encrypt ? c.encryptedFileName : c.plainFileName;
      final body = c.encrypt
          ? BackupCrypto.encrypt(json, c.passphrase)
          : Uint8List.fromList(utf8.encode(json));

      final response = await _client(c)
          .put(
            Uri.parse('${c.baseUrl}/$fileName'),
            headers: {'Content-Type': 'application/octet-stream'},
            body: body,
          )
          .timeout(const Duration(seconds: 60));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final now = DateTime.now().toUtc();
        await _storage.write(key: _lastSyncKey, value: now.toIso8601String());
        return WebDavSyncResult.success(now);
      }
      return WebDavSyncResult.failure('http_${response.statusCode}');
    } on Exception catch (e) {
      return WebDavSyncResult.failure(
        e.toString().contains('TimeoutException') ? 'timeout' : 'network',
      );
    }
  }

  /// Downloads and (if needed) decrypts the stored backup.
  /// Returns the plain JSON, or null when no backup exists.
  /// Throws [BackupCryptoException] when the passphrase no longer matches.
  Future<String?> downloadBackup(WebDavConfig c) async {
    final candidates = [
      if (c.encrypt) c.encryptedFileName,
      if (c.encrypt) c.plainFileName,
      c.plainFileName,
      if (!c.encrypt) c.encryptedFileName,
    ];
    for (final fileName in candidates.toSet()) {
      try {
        final response = await _client(c)
            .get(Uri.parse('${c.baseUrl}/$fileName'))
            .timeout(const Duration(seconds: 60));
        if (response.statusCode == 404) continue;
        if (response.statusCode != 200) {
          throw const BackupCryptoException('download_failed');
        }
        final bytes = response.bodyBytes;
        if (BackupCrypto.isEncryptedPayload(bytes)) {
          return BackupCrypto.decrypt(bytes, c.passphrase);
        }
        return utf8.decode(bytes, allowMalformed: true);
      } on BackupCryptoException {
        rethrow;
      } on Exception catch (e) {
        if (e.toString().contains('TimeoutException')) {
          throw const BackupCryptoException('timeout');
        }
        continue; // try next candidate name
      }
    }
    return null;
  }
}

/// http.Client that attaches a Basic-Authorization header to every request.
class _BasicAuthClient extends http.BaseClient {
  _BasicAuthClient(this._username, this._password);

  final String _username;
  final String _password;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] =
        'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
