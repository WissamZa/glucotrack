/**
 * Google Drive Sync Helper
 *
 * This module encapsulates all interactions with the Google Drive REST API.
 * It uses an OAuth2 access token (obtained via Google Identity Services on
 * the client) to upload/download a single JSON backup file named
 * `glucotrack-backup.json` in the user's Drive appDataFolder.
 *
 * The appDataFolder is a special hidden folder scoped to this app —
 * the user's other Drive files are never touched.
 */

const DRIVE_API = "https://www.googleapis.com/drive/v3";
const UPLOAD_API = "https://www.googleapis.com/upload/drive/v3";
const BACKUP_FILENAME = "glucotrack-backup.json";
const BACKUP_MIME = "application/json";

export interface DriveBackup {
  app: "glucotrack";
  version: number;
  exportedAt: string;
  readings: Array<{
    id: string;
    value: number;
    type: string;
    timestamp: string;
    notes?: string | null;
    carbs?: number | null;
    insulin?: number | null;
  }>;
  reminders: Array<{
    id: string;
    time: string;
    label: string;
    type: string;
    enabled: boolean;
  }>;
  settings: Record<string, unknown> | null;
}

/**
 * Find the backup file in appDataFolder.
 * Returns the file ID if found, otherwise null.
 */
export async function findBackupFile(accessToken: string): Promise<string | null> {
  const url = new URL(`${DRIVE_API}/files`);
  url.searchParams.set(
    "q",
    `name='${BACKUP_FILENAME}'`,
  );
  url.searchParams.set("spaces", "appDataFolder");
  url.searchParams.set("fields", "files(id,name,modifiedTime,size)");

  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Drive listFiles failed: ${res.status} ${errText}`);
  }

  const data = await res.json();
  return data.files?.[0]?.id ?? null;
}

/**
 * Create or update the backup file in appDataFolder with the given JSON payload.
 * Uses multipart upload to send metadata + content in a single request.
 */
export async function uploadBackup(
  accessToken: string,
  payload: DriveBackup,
): Promise<{ fileId: string; created: boolean }> {
  const existingId = await findBackupFile(accessToken);
  const json = JSON.stringify(payload, null, 2);

  // Multipart body: metadata + content
  const boundary = "glucotrack_" + Math.random().toString(36).slice(2);
  const metadata = {
    name: BACKUP_FILENAME,
    mimeType: BACKUP_MIME,
    ...(existingId ? {} : { parents: ["appDataFolder"] }),
  };

  const body =
    `--${boundary}\r\n` +
    "Content-Type: application/json; charset=UTF-8\r\n\r\n" +
    JSON.stringify(metadata) +
    "\r\n" +
    `--${boundary}\r\n` +
    `Content-Type: ${BACKUP_MIME}\r\n\r\n` +
    json +
    `\r\n--${boundary}--`;

  const method = existingId ? "PATCH" : "POST";
  const url = existingId
    ? `${UPLOAD_API}/files/${existingId}?uploadType=multipart&fields=id`
    : `${UPLOAD_API}/files?uploadType=multipart&fields=id`;

  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": `multipart/related; boundary=${boundary}`,
    },
    body,
  });

  if (!res.ok) {
    const errText = await res.text();
    throw new Error(`Drive upload failed: ${res.status} ${errText}`);
  }

  const data = await res.json();
  return { fileId: data.id, created: !existingId };
}

/**
 * Download the backup file and parse it as JSON.
 * Throws if the file does not exist or is invalid.
 */
export async function downloadBackup(
  accessToken: string,
): Promise<{ backup: DriveBackup; fileId: string; modifiedTime: string }> {
  const fileId = await findBackupFile(accessToken);
  if (!fileId) {
    throw new Error("no_backup_found");
  }

  // Get metadata + content
  const metaUrl = new URL(`${DRIVE_API}/files/${fileId}`);
  metaUrl.searchParams.set("fields", "id,name,modifiedTime");
  const metaRes = await fetch(metaUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!metaRes.ok) {
    throw new Error(`Drive getMetadata failed: ${metaRes.status}`);
  }
  const meta = await metaRes.json();

  const contentRes = await fetch(`${DRIVE_API}/files/${fileId}?alt=media`, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!contentRes.ok) {
    throw new Error(`Drive download failed: ${contentRes.status}`);
  }

  const text = await contentRes.text();
  let backup: DriveBackup;
  try {
    backup = JSON.parse(text);
  } catch {
    throw new Error("invalid_backup_format");
  }

  if (backup.app !== "glucotrack") {
    throw new Error("invalid_backup_app");
  }

  return { backup, fileId, modifiedTime: meta.modifiedTime };
}

/**
 * Get the user's email from Google userinfo endpoint.
 * Used to display which account is connected.
 */
export async function getUserEmail(accessToken: string): Promise<string> {
  const res = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  if (!res.ok) {
    throw new Error(`userinfo failed: ${res.status}`);
  }
  const data = await res.json();
  return data.email || "";
}
