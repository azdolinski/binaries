#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARIES_DIR="${REPO_ROOT}/binaries"

mkdir -p "${BINARIES_DIR}"

NANO_GIT_URL="https://git.savannah.gnu.org/git/nano.git"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

LATEST_TAG_RAW="$(git ls-remote --tags --refs "${NANO_GIT_URL}" | awk '{print $2}' | sed 's#refs/tags/##' | sort -V | tail -n 1)"

if [[ -z "${LATEST_TAG_RAW}" ]]; then
  echo "Could not resolve latest nano tag from Savannah Git."
  exit 1
fi

if [[ "${LATEST_TAG_RAW}" == v* ]]; then
  LATEST_TAG="${LATEST_TAG_RAW}"
else
  LATEST_TAG="v${LATEST_TAG_RAW}"
fi

SRC_DIR="${TMP_DIR}/nano-src"
git clone --depth 1 --branch "${LATEST_TAG_RAW}" "${NANO_GIT_URL}" "${SRC_DIR}"

pushd "${SRC_DIR}" > /dev/null
./autogen.sh

if [[ ! -f "${SRC_DIR}/configure" ]]; then
  echo "nano autogen step did not produce configure. Check build dependencies (autopoint/gettext)."
  exit 1
fi

./configure
make -j"$(nproc)"
popd > /dev/null

if [[ ! -f "${SRC_DIR}/src/nano" ]]; then
  echo "Build finished but nano binary is missing."
  exit 1
fi

VERSIONED_BINARY_PATH="${BINARIES_DIR}/nano.${LATEST_TAG}"
LATEST_BINARY_PATH="${BINARIES_DIR}/nano.latest"

install -m 0755 "${SRC_DIR}/src/nano" "${VERSIONED_BINARY_PATH}"
install -m 0755 "${SRC_DIR}/src/nano" "${LATEST_BINARY_PATH}"

md5sum "${VERSIONED_BINARY_PATH}" | awk '{print $1}' > "${VERSIONED_BINARY_PATH}.md5"
md5sum "${LATEST_BINARY_PATH}" | awk '{print $1}' > "${LATEST_BINARY_PATH}.md5"

echo "Latest nano synchronized: ${LATEST_TAG}"
