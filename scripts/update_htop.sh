#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARIES_DIR="${REPO_ROOT}/binaries"

mkdir -p "${BINARIES_DIR}"

API_URL="https://api.github.com/repos/htop-dev/htop/releases/latest"
LATEST_TAG_RAW="$(curl -fsSL "${API_URL}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')"

if [[ -z "${LATEST_TAG_RAW}" || "${LATEST_TAG_RAW}" == "null" ]]; then
  echo "Could not resolve latest htop tag from GitHub API."
  exit 1
fi

LATEST_TAG_VERSION="${LATEST_TAG_RAW#v}"
LATEST_TAG="v${LATEST_TAG_VERSION}"
ASSET_URL="https://github.com/htop-dev/htop/releases/download/${LATEST_TAG_VERSION}/htop-${LATEST_TAG_VERSION}.tar.xz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

ARCHIVE_PATH="${TMP_DIR}/htop.tar.xz"

curl -fL "${ASSET_URL}" -o "${ARCHIVE_PATH}"
tar -xJf "${ARCHIVE_PATH}" -C "${TMP_DIR}"

SRC_DIR="$(find "${TMP_DIR}" -maxdepth 1 -type d -name 'htop-*' | head -n 1)"
if [[ -z "${SRC_DIR}" ]]; then
  echo "Could not find extracted htop source directory."
  exit 1
fi

pushd "${SRC_DIR}" > /dev/null
./configure
make -j"$(nproc)"
popd > /dev/null

if [[ ! -f "${SRC_DIR}/htop" ]]; then
  echo "Build finished but htop binary is missing."
  exit 1
fi

VERSIONED_BINARY_PATH="${BINARIES_DIR}/htop.${LATEST_TAG}"
LATEST_BINARY_PATH="${BINARIES_DIR}/htop.latest"

install -m 0755 "${SRC_DIR}/htop" "${VERSIONED_BINARY_PATH}"
install -m 0755 "${SRC_DIR}/htop" "${LATEST_BINARY_PATH}"

md5sum "${VERSIONED_BINARY_PATH}" | awk '{print $1}' > "${VERSIONED_BINARY_PATH}.md5"
md5sum "${LATEST_BINARY_PATH}" | awk '{print $1}' > "${LATEST_BINARY_PATH}.md5"

echo "Latest htop synchronized: ${LATEST_TAG}"
