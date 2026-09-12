# WebDAV Sync — User Guide

GlucoTrack can back up all its data (readings, medication schedules, medication log, weight & blood pressure, water log, settings) to **any WebDAV server you choose**. Unlike provider-specific integrations, WebDAV needs **no developer account or OAuth registration** — you bring your own storage.

## Privacy & encryption

- The backup is **encrypted on your phone before upload**: AES-256-GCM with a key derived from your passphrase (PBKDF2-HMAC-SHA256, 100,000 iterations, random salt & nonce per backup).
- The server stores only **ciphertext** — the provider (or anyone who gains access to the server) cannot read your health data without the passphrase.
- Your server credentials (URL / username / password / passphrase) are stored in the phone's **secure storage** (Android Keystore / iOS Keychain), never in the app database and never sent anywhere except to your own server.
- The file is uploaded over HTTPS when your server URL uses `https://`. For self-hosted LAN servers `http://` works too, but encryption is strongly recommended then.

## Recommended services

Any WebDAV-capable storage works:

| Service | Notes |
|---|---|
| **Nextcloud / ownCloud** | Self-hosted or provider-hosted; create a folder, use its DAV URL |
| **Koofr** | Free tier, WebDAV enabled by default |
| **Synology / QNAP** | NAS built-in WebDAV Server package |
| **Mailbox.org, Fastmail** | Paid suites with WebDAV file storage |

## Setup (in the app)

1. **Settings → Integrations → WebDAV Sync**.
2. Enter the **folder URL** (ends with your chosen folder), e.g.
   `https://cloud.example.com/remote.php/dav/files/USER/glucotrack/`
3. Enter your **username** and **password** (use an app password if your provider supports them).
4. Keep **"Encrypt backup before upload"** on and set a **passphrase**. Store that passphrase safely — the backup cannot be restored without it (by design: nobody, including the storage provider, can read it).
5. Tap **Save & test connection** — the app checks the folder (PROPFIND) before saving.
6. Use **Sync now** to upload a full backup (one file, `glucotrack_backup.bin`, overwritten each time), and **Restore** on any device to download and merge it (duplicates are skipped; water days keep the higher count).

## Restore on a new device

Install GlucoTrack, configure the same WebDAV folder + the **same passphrase**, tap **Restore** — the backup merges into the new device's database. Local data is never deleted by a restore; it only adds.

## Technical notes

- Encrypted file format: ASCII magic `GCTE1` + 16-byte salt + 12-byte nonce + AES-GCM ciphertext (includes the 16-byte authentication tag). Detectable automatically on restore.
- Upload is a single `PUT` per sync; the previous backup is overwritten (no unbounded growth).
- Works on every platform the app supports, including desktop — no platform plugin required.
