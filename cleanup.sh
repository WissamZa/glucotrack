#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# GlucoTrack — Repo Cleanup Script
# Run this from the ROOT of the glucotrack repo:
#   chmod +x cleanup.sh && ./cleanup.sh
#
# Removes all files and folders that are not part of the Next.js app,
# not needed for CI/CD, and not standard config.
# ─────────────────────────────────────────────────────────────────────────────

set -e
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "🧹 Starting GlucoTrack repo cleanup..."
echo "Working directory: $(pwd)"
echo ""

# ── 1. FOLDERS ────────────────────────────────────────────────────────────────

# .zscripts/ — AI assistant / Z-AI dev tool scripts, not part of the app.
#   Referenced by "z-ai-web-dev-sdk" (a dev IDE tool), never used at runtime.
rm -rf .zscripts
echo "✅  Removed: .zscripts/"

# download/ — looks like a scratch/output folder; not imported anywhere in src/
rm -rf download
echo "✅  Removed: download/"

# examples/websocket/ — prototype/experiment folder, not wired into the app
rm -rf examples
echo "✅  Removed: examples/"

# mini-services/ — auxiliary microservice experiments (not referenced by next.js app)
rm -rf mini-services
echo "✅  Removed: mini-services/"

# db/ — SQLite database files. Should NEVER be committed to version control.
#   Prisma auto-creates the DB at runtime from DATABASE_URL in .env.
#   Already partially covered by .gitignore (*.db files), but the folder
#   itself may have been committed with placeholder files.
rm -rf db
echo "✅  Removed: db/"

# ── 2. ROOT FILES ─────────────────────────────────────────────────────────────

# Caddyfile — a reverse-proxy config for a self-hosted Caddy server.
#   The app deploys to GitHub Pages (static) or as a standalone Next.js server.
#   Caddy is not mentioned in any CI workflow or README deployment section.
rm -f Caddyfile
echo "✅  Removed: Caddyfile"

# ── 3. GITIGNORE — add entries to prevent these from coming back ──────────────

cat >> .gitignore << 'EOF'

# Cleanup: files removed by cleanup.sh — prevent from being re-added
/download/
/examples/
/mini-services/
/db/*.db
/db/*.db-journal
Caddyfile
EOF
echo "✅  Updated: .gitignore (added entries for removed paths)"

# ── 4. PACKAGE.JSON — remove unused dependency ────────────────────────────────
# "z-ai-web-dev-sdk" is a Z-AI IDE integration package, not part of the app.
# It ships no UI or runtime logic used by GlucoTrack; it's a dev-environment tool.
if command -v node &>/dev/null; then
  node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    const removed = [];
    ['z-ai-web-dev-sdk'].forEach(dep => {
      if (pkg.dependencies && pkg.dependencies[dep]) {
        delete pkg.dependencies[dep];
        removed.push(dep);
      }
    });
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    if (removed.length) console.log('✅  Removed from package.json dependencies:', removed.join(', '));
    else console.log('ℹ️   z-ai-web-dev-sdk was not found in dependencies (already clean)');
  "
else
  echo "⚠️  Node not found — manually remove 'z-ai-web-dev-sdk' from package.json dependencies"
fi

# ── 5. SUMMARY ────────────────────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────────────────────────────────────────"
echo "✅ Cleanup complete! What was removed and why:"
echo ""
echo "  FOLDER            REASON"
echo "  .zscripts/        Z-AI IDE helper scripts — dev tool only, not app code"
echo "  download/         Scratch/output folder — nothing imports from it"
echo "  examples/         WebSocket experiment — not wired into the Next.js app"
echo "  mini-services/    Microservice experiments — not referenced by the app"
echo "  db/               SQLite DB files — must not be in version control;"
echo "                    Prisma creates them at runtime from DATABASE_URL"
echo ""
echo "  FILE              REASON"
echo "  Caddyfile         Caddy reverse-proxy config — not used in any CI/CD"
echo "                    workflow or deployment; app uses GitHub Pages / standalone"
echo ""
echo "  DEPENDENCY        REASON"
echo "  z-ai-web-dev-sdk  Z-AI IDE integration SDK — dev environment tool only,"
echo "                    adds ~0 runtime value and bloats installs"
echo ""
echo "Next steps:"
echo "  1. Run: bun install   (to sync lockfile after package.json change)"
echo "  2. Run: git add -A && git commit -m 'chore: remove unnecessary files and folders'"
echo "  3. Push to main"
echo "─────────────────────────────────────────────────────────────────────────────"
