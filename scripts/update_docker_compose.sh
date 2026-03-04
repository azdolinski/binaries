#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARIES_DIR="${REPO_ROOT}/binaries"

mkdir -p "${BINARIES_DIR}"

FORCE_REBUILD="${FORCE_REBUILD:-false}"

retry() {
  local attempts="$1"
  local delay_seconds="$2"
  shift 2

  local i
  for i in $(seq 1 "${attempts}"); do
    if "$@"; then
      return 0
    fi

    if [[ "${i}" -lt "${attempts}" ]]; then
      echo "Command failed (attempt ${i}/${attempts}): $*"
      echo "Retrying in ${delay_seconds}s..."
      sleep "${delay_seconds}"
    fi
  done

  return 1
}

API_URL="https://api.github.com/repos/docker/compose/releases/latest"
LATEST_TAG="$(retry 5 10 curl -fsSL "${API_URL}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"

if [[ -z "${LATEST_TAG}" || "${LATEST_TAG}" == "null" ]]; then
  echo "Could not resolve latest docker-compose tag from GitHub API."
  exit 1
fi

VERSIONED_BINARY_PATH="${BINARIES_DIR}/docker-compose.${LATEST_TAG}"
LATEST_BINARY_PATH="${BINARIES_DIR}/docker-compose.latest"

if [[ -f "${VERSIONED_BINARY_PATH}" && "${FORCE_REBUILD}" != "true" ]]; then
  install -m 0755 "${VERSIONED_BINARY_PATH}" "${LATEST_BINARY_PATH}"
  md5sum "${VERSIONED_BINARY_PATH}" | awk '{print $1}' > "${VERSIONED_BINARY_PATH}.md5"
  md5sum "${LATEST_BINARY_PATH}" | awk '{print $1}' > "${LATEST_BINARY_PATH}.md5"
  echo "Latest docker-compose already available: ${LATEST_TAG}. Skipping download."
  exit 0
fi

if [[ -f "${VERSIONED_BINARY_PATH}" && "${FORCE_REBUILD}" == "true" ]]; then
  echo "Force rebuild enabled for docker-compose ${LATEST_TAG}."
fi

ASSET_URL="https://github.com/docker/compose/releases/download/${LATEST_TAG}/docker-compose-linux-x86_64"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

DOWNLOADED_BINARY="${TMP_DIR}/docker-compose"
retry 5 10 curl -fL "${ASSET_URL}" -o "${DOWNLOADED_BINARY}"

install -m 0755 "${DOWNLOADED_BINARY}" "${VERSIONED_BINARY_PATH}"
install -m 0755 "${DOWNLOADED_BINARY}" "${LATEST_BINARY_PATH}"

md5sum "${VERSIONED_BINARY_PATH}" | awk '{print $1}' > "${VERSIONED_BINARY_PATH}.md5"
md5sum "${LATEST_BINARY_PATH}" | awk '{print $1}' > "${LATEST_BINARY_PATH}.md5"

echo "Latest docker-compose synchronized: ${LATEST_TAG}"
