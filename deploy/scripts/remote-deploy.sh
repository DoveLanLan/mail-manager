#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/compose.production.yml"
COMPOSE_ARGS=(-f "$COMPOSE_FILE")
REQUESTED_MAIL_MANAGER_IMAGE="${MAIL_MANAGER_IMAGE:-}"

generate_password() {
  openssl rand -base64 18 | tr -d '\n'
}

generate_secret_key() {
  openssl rand -hex 32
}

mkdir -p "$ROOT_DIR/data"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  umask 077
  {
    grep -Ev '^(LOGIN_PASSWORD|SECRET_KEY)=' "$ROOT_DIR/.env.example"
    echo "LOGIN_PASSWORD=$(generate_password)"
    echo "SECRET_KEY=$(generate_secret_key)"
  } > "$ROOT_DIR/.env"
  echo "Created $ROOT_DIR/.env with generated LOGIN_PASSWORD and SECRET_KEY."
fi

if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source "$ROOT_DIR/.env"
  set +a
fi

if [[ -n "$REQUESTED_MAIL_MANAGER_IMAGE" ]]; then
  MAIL_MANAGER_IMAGE="$REQUESTED_MAIL_MANAGER_IMAGE"
fi

: "${MAIL_MANAGER_IMAGE:?MAIL_MANAGER_IMAGE must be set}"
: "${TAILSCALE_BIND_IP:?TAILSCALE_BIND_IP must be set}"
: "${LOGIN_PASSWORD:?LOGIN_PASSWORD must be set}"
: "${SECRET_KEY:?SECRET_KEY must be set}"

if [[ "$LOGIN_PASSWORD" == "change-me" || "$SECRET_KEY" == "change-me" ]]; then
  echo "error: replace placeholder LOGIN_PASSWORD and SECRET_KEY in $ROOT_DIR/.env" >&2
  exit 1
fi

GATEWAY_NETWORK="${GATEWAY_NETWORK:-vps-gateway}"
export GATEWAY_NETWORK

docker network inspect "$GATEWAY_NETWORK" >/dev/null 2>&1 || docker network create "$GATEWAY_NETWORK" >/dev/null

if [[ -n "${GHCR_USERNAME:-}" && -n "${GHCR_TOKEN:-}" ]]; then
  printf '%s\n' "$GHCR_TOKEN" | docker login ghcr.io -u "$GHCR_USERNAME" --password-stdin >/dev/null
fi

cd "$ROOT_DIR"
docker compose "${COMPOSE_ARGS[@]}" pull
docker compose "${COMPOSE_ARGS[@]}" up -d --remove-orphans
docker compose "${COMPOSE_ARGS[@]}" ps
