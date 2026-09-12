# Google Drive Sync — Setup Guide

GlucoTrack's Drive backup uses the **most restrictive Google scope available**: `https://www.googleapis.com/auth/drive.appdata`. With it, the app can only read/write its own hidden `appDataFolder` on the user's Drive — invisible in the Drive UI and unreachable by any other app. GlucoTrack **cannot** read, list, or modify any other file in the user's Drive.

Data flows **directly** between the phone and `googleapis.com` — there is no intermediary server, and the backup is a plain GlucoTrack JSON export of the same format used by the in-app manual backup.

## First-run requirement (app owner, one time)

For Google sign-in to succeed, the package `com.wissamza.glucotrack` must be registered with Google:

1. Open [Google Cloud Console](https://console.cloud.google.com/) and create (or pick) a project.
2. **APIs & Services → Library → enable "Google Drive API"**.
3. **APIs & Services → OAuth consent screen**:
   - User type: *External* (or *Internal* for Workspace).
   - Add the scope `…/auth/drive.appdata` to the app's declared scopes.
   - While the app is in *Testing* mode, only added test users can sign in; publish the app to allow anyone.
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**:
   - **Application type: Android**
   - **Package name:** `com.wissamza.glucotrack`
   - **SHA-1:** the fingerprint of the signing key (release keystore *and* debug keystore if you test debug builds):
     ```bash
     keytool -list -v -keystore release.keystore -alias glucotrack | grep SHA1
     ```
5. No API key or client secret is stored in the app — Android identifies the client by package name + SHA-1.

## What the user sees in the app

**Settings → Integrations → Google Drive Sync**:

- **Sign in & sync** — Google account picker, then a consent dialog showing that GlucoTrack requests access only to "its own app folder".
- **Sync now** — uploads a full JSON backup (readings, reminders incl. medication schedules, weight/BP, water log) as one file in the hidden folder. Subsequent syncs update the same file (no duplicates).
- **Restore backup** — downloads that file and merges it into the device (duplicates are skipped; water days take the higher count).
- **Sign out** — clears the local session. To fully revoke the grant, users can remove the app from their [Google account permissions page](https://myaccount.google.com/permissions).

## Privacy notes

- The requested scope grants access to **nothing** outside `appDataFolder`.
- Sign-in state is managed by Google Play services on-device; GlucoTrack stores no passwords or tokens itself (access tokens are held in-memory by the sign-in plugin for the duration of a sync).
- The backup file lives inside Google's infrastructure under the user's own account, is overwritten on every sync, and access can be revoked at any time from the app (Sign out) or from the [Google account permissions page](https://myaccount.google.com/permissions).
- Health data is sensitive: the backup JSON is uploaded **as-is** (like the manual JSON export). Users who prefer not to use cloud sync simply never sign in — the feature is fully optional and off by default.

## Platform support

Android & iOS (via `google_sign_in` 7.x). Desktop builds show the card as "Available on Android & iOS" and disable sign-in.
