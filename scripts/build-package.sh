#!/usr/bin/env bash
set -Eeuo pipefail
SOURCE_DIR="$(cd "${1:?pass upstream source directory}" && pwd)"
OUT_DIR="${2:?pass output directory}"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"
APP_ID='ai.storyteller.pdfcraft'
VERSION='0.21.1'
RELEASE='1kylin231'
NAME="pdfcraft-${VERSION}-kylin-glibc231-arm64"
if [[ "$(uname -m)" != 'aarch64' ]] || [[ "$(getconf GNU_LIBC_VERSION)" != 'glibc 2.31' ]]; then
  echo 'ERROR: Build requires native aarch64 and glibc 2.31' >&2
  exit 1
fi
test -f "$SOURCE_DIR/Cargo.lock"
grep -A 8 '^\[workspace.package\]' "$SOURCE_DIR/Cargo.toml" | grep -q '^version = "0.21.1"'
test -d "${CRAFT_I18N_DIR:?required}/locales"
export CRAFT_I18N_REQUIRED=1
export PDFCRAFT_BUILD_LABEL=kylin231
cd "$SOURCE_DIR"
cargo build --locked --release -p pdfcraft -p pdfcraft-cli
BIN="$SOURCE_DIR/target/release"
"$BIN/pdfcraft" --version
"$BIN/pdfcraft-cli" --version
STAGE="$(mktemp -d)"
TAR_TOP="$(mktemp -d)"
trap 'rm -rf "$STAGE" "$TAR_TOP"' EXIT
install -Dm755 "$BIN/pdfcraft" "$STAGE/usr/bin/pdfcraft"
install -Dm755 "$BIN/pdfcraft-cli" "$STAGE/usr/bin/pdfcraft-cli"
install -Dm644 "$SOURCE_DIR/packaging/linux/$APP_ID.desktop" "$STAGE/usr/share/applications/$APP_ID.desktop"
install -Dm644 "$SOURCE_DIR/packaging/linux/$APP_ID.mime.xml" "$STAGE/usr/share/mime/packages/$APP_ID.xml"
install -d "$STAGE/usr/share/metainfo" "$STAGE/usr/share/icons" "$STAGE/usr/share/doc/pdfcraft"
sed -e "s/@VERSION@/$VERSION/g" -e "s/@DATE@/$(date -u +%Y-%m-%d)/g" "$SOURCE_DIR/packaging/linux/$APP_ID.metainfo.xml.in" > "$STAGE/usr/share/metainfo/$APP_ID.metainfo.xml"
cp -R "$SOURCE_DIR/assets/app-icon/hicolor" "$STAGE/usr/share/icons/"
for filename in README.md LICENSE-MIT LICENSE-APACHE NOTICE; do
  if [[ -f "$SOURCE_DIR/$filename" ]]; then
    cp "$SOURCE_DIR/$filename" "$STAGE/usr/share/doc/pdfcraft/"
  fi
done
# Download/verify OCR model assets during online GitHub build. The Kylin machine stays offline.
cargo xtask models "$STAGE/usr/share/pdfcraft/models"
test -s "$STAGE/usr/share/pdfcraft/models/ATTRIBUTION.txt"
if ! find "$STAGE/usr/share/pdfcraft/models" -name '*.LICENCE.txt' -print -quit | grep -q .; then
  echo 'ERROR: OCR model licences missing' >&2
  exit 1
fi
install -d "$STAGE/DEBIAN"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: pdfcraft
Version: ${VERSION}-${RELEASE}
Section: graphics
Priority: optional
Architecture: arm64
Maintainer: Unofficial Kylin compatibility build <noreply@users.noreply.github.com>
Homepage: https://github.com/storytold/pdfcraft
Depends: libc6 (>= 2.31), libgcc-s1, libxkbcommon0, libvulkan1 | libegl1
Recommends: libwayland-client0, libx11-6, libx11-xcb1, libxcursor1, libxi6, libxrandr2, cups-client
Description: PdfCraft PDF viewer/editor compatibility build for Kylin ARM64
 Built from PdfCraft v0.21.1 on Ubuntu 20.04 ARM64.
 Includes the GUI, CLI, translations and OCR model files.
EOF
install -Dm755 "$SOURCE_DIR/packaging/linux/postinst.sh" "$STAGE/DEBIAN/postinst"
install -Dm755 "$SOURCE_DIR/packaging/linux/postinst.sh" "$STAGE/DEBIAN/postrm"
dpkg-deb --build --root-owner-group "$STAGE" "$OUT_DIR/$NAME.deb"
mkdir -p "$TAR_TOP/$NAME"
cp -a "$STAGE/usr" "$TAR_TOP/$NAME/"
tar -C "$TAR_TOP" -czf "$OUT_DIR/$NAME.tar.gz" "$NAME"
echo "Built $OUT_DIR/$NAME.deb and $OUT_DIR/$NAME.tar.gz"
