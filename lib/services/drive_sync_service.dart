// Google Drive backup sync — least-privilege by design.
//
// Scope: ONLY `https://www.googleapis.com/auth/drive.appdata` — a hidden
// per-app data folder on the user's Drive that this app (and nothing else)
// can see. The app cannot read, write, or list ANY other Drive file, and the
// folder is invisible in the user's Drive UI. Data never touches our servers
// (there are none): the phone talks straight to googleapis.com.
//
// Uses google_sign_in 7.x (authenticate + authorizationClient) and plain
// REST calls via package:http — no broad Drive SDK dependency.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

/// The single Drive scope this app requests: the hidden app-data folder.
const String kDriveAppDataScope =
    'https://www.googleapis.com/auth/drive.appdata';

const String _backupFileName = 'glucotrack_backup.json';
const String _appDataFolder = 'appDataFolder';

/// Result of a sync operation.
class DriveSyncResult {
  final bool success;
  final String? error;
  final DateTime? lastBackupTime;

  const DriveSyncResult.success(this.lastBackupTime)
    : success = true,
      error = null;
  const DriveSyncResult.failure(this.error)
    : success = false,
      lastBackupTime = null;
}

class DriveSyncService {
  static final DriveSyncService _instance = DriveSyncService._internal();
  factory DriveSyncService() => _instance;
  DriveSyncService._internal();

  final GoogleSignIn _gsi = GoogleSignIn.instance;
  bool _initialized = false;

  /// True on platforms where the sign-in plugin is supported. Desktop is not.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _gsi.initialize();
    _initialized = true;
  }

  /// Silently restores a previous session, if any. Returns null otherwise.
  Future<GoogleSignInAccount?> currentUser() async {
    if (!isSupported) return null;
    try {
      await _ensureInitialized();
      return await _gsi.attemptLightweightAuthentication();
    } on Exception {
      return null;
    }
  }

  /// Interactive sign-in + Drive app-data authorization.
  /// MUST be called from a user gesture (button press).
  Future<GoogleSignInAccount> signIn() async {
    await _ensureInitialized();
    final account = await _gsi.authenticate(
      scopeHint: const [kDriveAppDataScope],
    );
    await account.authorizationClient.authorizeScopes(const [
      kDriveAppDataScope,
    ]);
    return account;
  }

  Future<void> signOut() => _gsi.signOut();

  http.Client _authorizedClient(String accessToken) =>
      _AuthorizedClient(accessToken);

  /// Uploads [jsonContent] as the single backup file in appDataFolder.
  /// Creates the file on first run, updates it afterwards.
  Future<DriveSyncResult> uploadBackup(String jsonContent) async {
    try {
      final account = await currentUser();
      if (account == null) {
        return const DriveSyncResult.failure('not_signed_in');
      }
      final authorization = await account.authorizationClient
          .authorizationForScopes(const [kDriveAppDataScope]);
      if (authorization == null) {
        return const DriveSyncResult.failure('not_authorized');
      }
      final client = _authorizedClient(authorization.accessToken);

      final existingId = await _findBackupFileId(client);
      if (existingId != null) {
        // PATCH media upload — same file, same permissions, no duplicates.
        final response = await client.patch(
          Uri.https(
            'www.googleapis.com',
            '/upload/drive/v3/files/$existingId',
            {'uploadType': 'media'},
          ),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonContent,
        );
        if (response.statusCode != 200) {
          return DriveSyncResult.failure(
            'upload_failed_${response.statusCode}',
          );
        }
      } else {
        // Multipart create with appDataFolder parent — the documented
        // multipart/related format: metadata part, then media part.
        final boundary = 'glucotrack_${DateTime.now().millisecondsSinceEpoch}';
        final metadata = jsonEncode({
          'name': _backupFileName,
          'parents': [_appDataFolder],
        });
        final body =
            '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$metadata\r\n'
            '--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$jsonContent\r\n'
            '--$boundary--';
        final response = await client
            .post(
              Uri.https('www.googleapis.com', '/upload/drive/v3/files', {
                'uploadType': 'multipart',
              }),
              headers: {
                'Content-Type': 'multipart/related; boundary=$boundary',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 60));
        if (response.statusCode != 200 && response.statusCode != 201) {
          return DriveSyncResult.failure(
            'upload_failed_${response.statusCode}',
          );
        }
      }
      return DriveSyncResult.success(DateTime.now().toUtc());
    } on Exception catch (e) {
      return DriveSyncResult.failure(e.toString());
    }
  }

  /// Downloads the stored backup JSON, or null when no backup exists yet.
  Future<String?> downloadBackup() async {
    final account = await currentUser();
    if (account == null) return null;
    final authorization = await account.authorizationClient
        .authorizationForScopes(const [kDriveAppDataScope]);
    if (authorization == null) return null;
    final client = _authorizedClient(authorization.accessToken);

    final fileId = await _findBackupFileId(client);
    if (fileId == null) return null;
    final response = await client
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {
            'alt': 'media',
          }),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) return null;
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  /// Last-modified time of the stored backup (from Drive metadata), used to
  /// show "آخر نسخة احتياطية" without storing anything locally.
  Future<DateTime?> lastBackupTime() async {
    try {
      final account = await currentUser();
      if (account == null) return null;
      final authorization = await account.authorizationClient
          .authorizationForScopes(const [kDriveAppDataScope]);
      if (authorization == null) return null;
      final client = _authorizedClient(authorization.accessToken);
      final id = await _findBackupFileId(client);
      if (id == null) return null;
      final response = await client.get(
        Uri.https('www.googleapis.com', '/drive/v3/files/$id', {
          'fields': 'modifiedTime',
        }),
      );
      if (response.statusCode != 200) return null;
      return DateTime.tryParse(
        (jsonDecode(response.body) as Map<String, dynamic>)['modifiedTime']
                as String? ??
            '',
      );
    } on Exception {
      return null;
    }
  }

  Future<String?> _findBackupFileId(http.Client client) async {
    final response = await client
        .get(
          Uri.https('www.googleapis.com', '/drive/v3/files', {
            'spaces': _appDataFolder,
            'fields': 'files(id,name)',
            'pageSize': '20',
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;
    final files =
        (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List?;
    for (final f in files ?? const []) {
      if ((f as Map<String, dynamic>)['name'] == _backupFileName) {
        return f['id'] as String;
      }
    }
    return null;
  }
}

/// http.Client that attaches the OAuth Bearer header to every request.
class _AuthorizedClient extends http.BaseClient {
  _AuthorizedClient(this._accessToken);
  final String _accessToken;
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
