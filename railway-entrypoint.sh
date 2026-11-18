#!/bin/sh
# Maps Railway onto dufs: $PORT, the /data volume, and a login built from the
# USERNAME / PASSWORD variables. Nothing here exits on a bad variable: it logs and
# falls back, so a typo never leaves the service crash-looping.
set -u

log() { echo "railway: $*"; }

case "${PORT:-}" in
  ''|*[!0-9]*) log "PORT='${PORT:-}' is not a number, using 5000"; PORT=5000 ;;
esac

ROOT=/data
mkdir -p "$ROOT"
[ -w "$ROOT" ] || log "warning: $ROOT is not writable, uploads will fail (is the volume mounted?)"

set -- "$ROOT" --port "$PORT" \
  --allow-upload --allow-delete --allow-search --allow-archive --allow-hash

# Railway volumes carry a lost+found folder at their root; keep it out of the listing.
# A --hidden flag replaces DUFS_HIDDEN entirely, so fold the user's value in.
set -- "$@" --hidden "lost+found${DUFS_HIDDEN:+,$DUFS_HIDDEN}"
unset DUFS_HIDDEN

if [ -n "${DUFS_AUTH:-}" ]; then
  # Advanced: the user wrote dufs's own rules (user:pass@/path:rw|@/...). Pass them as they are.
  log "using the auth rules in DUFS_AUTH; USERNAME, PASSWORD and PUBLIC_READ are ignored"
else
  user=$(printf '%s' "${USERNAME:-}" | tr -d '[:space:]')
  case "$user" in
    '') user=admin ;;
    *[:@\|/]*) log "USERNAME may not contain : @ | or /, using 'admin'"; user=admin ;;
  esac

  pass=${PASSWORD:-}
  if [ -z "$pass" ]; then
    # Never serve the volume open by accident: make a one-off password and print it.
    pass=$(head -c 18 /dev/urandom | base64 | tr -d '/+=')
    log "PASSWORD is empty. A temporary password for this boot only: $pass"
    log "set the PASSWORD variable to keep one that survives restarts"
  fi

  # dufs splits a rule at '|' and at the first '@/', so a password holding either
  # would break the rule. Store such a password as a SHA-512 crypt hash instead
  # (basic auth still works; digest auth doesn't with hashes, browsers use basic).
  case "$pass" in
    *'|'*|*'@/'*)
      hash=$(mkpasswd -m sha512 "$pass" 2>/dev/null || openssl passwd -6 "$pass" 2>/dev/null)
      case "$hash" in
        '$6$'*) pass=$hash ;;
        *) pass=$(head -c 18 /dev/urandom | base64 | tr -d '/+=')
           log "PASSWORD holds '|' or '@/' and could not be hashed. A temporary password for this boot only: $pass" ;;
      esac ;;
  esac
  set -- "$@" --auth "$user:$pass@/:rw"

  case "$(printf '%s' "${PUBLIC_READ:-false}" | tr '[:upper:]' '[:lower:]')" in
    true|1|yes|on) log "PUBLIC_READ is on: anyone can browse and download, only $user can change files"
                   set -- "$@" --auth "@/" ;;
  esac
fi

# Railway counts the kernel's cache of files the container has read or written as
# the service's memory, and with no memory pressure it is never freed: serving a few
# large files would keep showing as gigabytes. Drop it every 15 minutes.
( while sleep 900; do nice -n 19 drop-file-cache "$ROOT" /tmp; done ) &

log "serving $ROOT on port $PORT"
exec dufs "$@"
