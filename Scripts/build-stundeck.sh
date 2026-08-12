#!/bin/bash
set -euo pipefail

# Reproducibly cross-build StunDeck for the QWRT OpenWrt target.
# The source commit includes the OpenWrt fw4 gateway implementation merged in PR #1.
readonly STUNDECK_REPO="https://github.com/yefeng8771/stundeck"
readonly STUNDECK_COMMIT="87930bf1a3957cd7bfcd2307aa143711e45edef7"
readonly STUNDECK_SOURCE_SHA256="f811b92a285179061a74f990804e0ea0c0f09342be63d085ea2644bdac7f24db"
readonly STUNDECK_VERSION="0.1.0"

WORKSPACE="${GITHUB_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
WRT_ROOT="${1:-${WORKSPACE}/${WRT_DIR:-wrt}}"
PACKAGE_DIR="${WRT_ROOT}/package/stundeck"
OUT_DIR="${WRT_ROOT}/build_dir/stundeck-prebuilt"
CACHE_DIR="${WORKSPACE}/.cache/stundeck"
CONFIG_FILE="${WRT_ROOT}/.config"

[ -f "$CONFIG_FILE" ] || {
    echo "[stundeck] OpenWrt config is missing: $CONFIG_FILE" >&2
    exit 1
}
OWRT_ARCH="$(grep -m 1 '^CONFIG_TARGET_ARCH_PACKAGES=' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '\"')"
case "$OWRT_ARCH" in
    aarch64*|arm64*) GOARCH=arm64 ;;
    *)
        echo "[stundeck] Unsupported OpenWrt target architecture: ${OWRT_ARCH:-<empty>} (QWRT requires aarch64)" >&2
        exit 1
        ;;
esac

[ -f "${PACKAGE_DIR}/Makefile" ] || {
    echo "[stundeck] Package template is missing: ${PACKAGE_DIR}" >&2
    exit 1
}
command -v go >/dev/null || { echo "[stundeck] Go is required" >&2; exit 1; }

GO_VERSION="$(go env GOVERSION)"
case "$GO_VERSION" in
    go1.2[5-9]*|go1.[3-9][0-9]*) ;;
    *) echo "[stundeck] Go >= 1.25 is required, found $GO_VERSION" >&2; exit 1 ;;
esac

mkdir -p "$CACHE_DIR" "$OUT_DIR"
ARCHIVE="${CACHE_DIR}/${STUNDECK_COMMIT}.tar.gz"
SOURCE_DIR="${CACHE_DIR}/source-${STUNDECK_COMMIT}"
SOURCE_URL="${STUNDECK_REPO}/archive/${STUNDECK_COMMIT}.tar.gz"

if [ ! -f "$ARCHIVE" ]; then
    echo "[stundeck] Downloading source at $STUNDECK_COMMIT"
    curl --fail --location --retry 3 --retry-delay 2 "$SOURCE_URL" --output "$ARCHIVE"
fi
ACTUAL_SOURCE_SHA256="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [ "$ACTUAL_SOURCE_SHA256" != "$STUNDECK_SOURCE_SHA256" ]; then
    echo "[stundeck] Source checksum mismatch: expected $STUNDECK_SOURCE_SHA256, got $ACTUAL_SOURCE_SHA256" >&2
    rm -f "$ARCHIVE"
    exit 1
fi

rm -rf "$SOURCE_DIR"
mkdir -p "$SOURCE_DIR"
tar -xzf "$ARCHIVE" --strip-components=1 -C "$SOURCE_DIR"

export CGO_ENABLED=0 GOOS=linux GOARCH
export GOFLAGS="-buildvcs=false -trimpath"
readonly LDFLAGS="-s -w -X github.com/Nciae-Zyh/stundeck/internal/version.Version=${STUNDECK_VERSION} -X github.com/Nciae-Zyh/stundeck/internal/version.Commit=${STUNDECK_COMMIT}"

echo "[stundeck] Building $STUNDECK_VERSION ($STUNDECK_COMMIT) for linux/$GOARCH with $GO_VERSION"
(
    cd "$SOURCE_DIR"
    go mod download
    go build -ldflags "$LDFLAGS" -o "$OUT_DIR/stundeck" ./cmd/stundeck
    go build -ldflags "$LDFLAGS" -o "$OUT_DIR/stundeck-notify" ./cmd/stundeck-notify
)

for binary in stundeck stundeck-notify; do
    file "$OUT_DIR/$binary" | grep -q 'ARM aarch64' || {
        echo "[stundeck] Unexpected binary architecture: $(file "$OUT_DIR/$binary")" >&2
        exit 1
    }
    chmod 0755 "$OUT_DIR/$binary"
done

# STUNDECK_* variables are consumed by package/stundeck/Makefile.
{
    echo "STUNDECK_BIN_DIR:=${OUT_DIR}"
    echo "STUNDECK_VERSION:=${STUNDECK_VERSION}"
} > "${WRT_ROOT}/stundeck-build.mk"

echo "[stundeck] Built binaries in $OUT_DIR"
sha256sum "$OUT_DIR/stundeck" "$OUT_DIR/stundeck-notify"
