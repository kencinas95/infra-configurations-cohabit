#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-encrypt}"
DELETE_PLAIN="false"
ITER="200000"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log() {
  local level="$1"
  local func="$2"
  local msg="$3"

  printf "%s %s [%s] %s: %s\n" \
    "$(timestamp)" \
    "$level" \
    "$MODE" \
    "$func" \
    "$msg"
}

log_info() { log "INFO" "${FUNCNAME[1]}" "$1"; }
log_warn() { log "WARN" "${FUNCNAME[1]}" "$1"; }
log_error() { log "ERROR" "${FUNCNAME[1]}" "$1"; }

usage() {
  cat <<'EOF'
Usage:
  ./runme.sh encrypt [--delete-plain]
  ./runme.sh decrypt
  ./runme.sh cleanup
  ./runme.sh -h | --help

Description:
  Encrypts or decrypts .env files inside the repository using OpenSSL.

Commands:
  encrypt           Encrypt all .env / *.env files to .env.enc
  decrypt           Decrypt all .env.enc files back to .env
  cleanup           Remove all plain .env / *.env files

Options:
  --delete-plain    After encryption, remove the original .env files
  -h, --help        Show this help message

Password:
  If REPO_PASSWORD environment variable exists it will be used.
  Otherwise the script will prompt interactively.

Examples:
  ./runme.sh encrypt
  ./runme.sh encrypt --delete-plain
  ./runme.sh decrypt
  ./runme.sh cleanup
EOF
}

# Help / option parsing
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${2:-}" == "--delete-plain" ]]; then
  DELETE_PLAIN="true"
fi

# Requirements
if ! command -v openssl >/dev/null 2>&1; then
  log_error "openssl no está instalado"
  exit 1
fi

get_password_encrypt() {
  if [[ -n "${REPO_PASSWORD:-}" ]]; then
    PASS="$REPO_PASSWORD"
    log_info "using password from REPO_PASSWORD"
    return
  fi

  local pass1 pass2
  read -r -s -p "Password: " pass1
  echo
  read -r -s -p "Confirm password: " pass2
  echo

  if [[ -z "$pass1" ]]; then
    log_error "password vacía"
    exit 1
  fi

  if [[ "$pass1" != "$pass2" ]]; then
    log_error "passwords no coinciden"
    exit 1
  fi

  PASS="$pass1"
}

get_password_decrypt() {
  if [[ -n "${REPO_PASSWORD:-}" ]]; then
    PASS="$REPO_PASSWORD"
    log_info "using password from REPO_PASSWORD"
    return
  fi

  read -r -s -p "Password: " PASS
  echo

  if [[ -z "$PASS" ]]; then
    log_error "password vacía"
    exit 1
  fi
}

encrypt_one() {
  local in="$1"
  local out="${in}.enc"

  # If out exists and is newer than in, skip
  if [[ -f "$out" && "$out" -nt "$in" ]]; then
    log_info "$out is up-to-date (skip)"
    return 0
  fi

  umask 077

  openssl enc -aes-256-cbc \
    -salt \
    -pbkdf2 \
    -iter "$ITER" \
    -md sha256 \
    -a \
    -pass "pass:$PASS" \
    -in "$in" \
    -out "$out"

  chmod 600 "$out" 2>/dev/null || true
  log_info "encrypted $in -> $out"

  if [[ "$DELETE_PLAIN" == "true" ]]; then
    rm -f "$in"
    log_warn "deleted plain file $in"
  fi
}

decrypt_one() {
  local in="$1"
  local out="${in%.enc}"

  if [[ -f "$out" ]]; then
    log_warn "$out already exists (skip)"
    return 0
  fi

  umask 077

  openssl enc -d -aes-256-cbc \
    -pbkdf2 \
    -iter "$ITER" \
    -md sha256 \
    -a \
    -pass "pass:$PASS" \
    -in "$in" \
    -out "$out"

  chmod 600 "$out" 2>/dev/null || true
  log_info "decrypted $in -> $out"
}

cleanup_envs() {
  mapfile -t PLAINS < <(
    find . -type f \
      \( -name ".env" -o -name "*.env" \) \
      ! -name "*.enc" \
      ! -path "*/.git/*"
  )

  if [[ "${#PLAINS[@]}" -eq 0 ]]; then
    log_info "no plain .env files found"
    return 0
  fi

  log_warn "removing ${#PLAINS[@]} plain env files"

  for f in "${PLAINS[@]}"; do
    rm -f "$f"
    log_warn "deleted $f"
  done
}

case "$MODE" in
  encrypt)
    get_password_encrypt
    mapfile -t TARGETS < <(
      find . -type f \
        \( -name ".env" -o -name "*.env" \) \
        ! -name "*.enc" \
        ! -path "*/.git/*"
    )

    if [[ "${#TARGETS[@]}" -eq 0 ]]; then
      log_info "no .env files found"
      exit 0
    fi

    log_info "encrypting ${#TARGETS[@]} env files"
    for f in "${TARGETS[@]}"; do
      encrypt_one "$f"
    done
    ;;

  decrypt)
    get_password_decrypt
    mapfile -t ENCS < <(
      find . -type f -name "*.env.enc" ! -path "*/.git/*"
    )

    if [[ "${#ENCS[@]}" -eq 0 ]]; then
      log_info "no .env.enc files found"
      exit 0
    fi

    log_info "decrypting ${#ENCS[@]} env files"
    for f in "${ENCS[@]}"; do
      decrypt_one "$f"
    done
    ;;

  cleanup)
    cleanup_envs
    ;;

  *)
    log_error "invalid command"
    usage
    exit 1
    ;;
esac

log_info "completed"