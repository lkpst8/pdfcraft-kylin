#!/usr/bin/env bash
set -euxo pipefail
test "$(uname -m)" = "aarch64"
test "$(getconf GNU_LIBC_VERSION)" = "glibc 2.31"
cd upstream
cargo build --release --locked -p pdfcraft -p pdfcraft-cli
cd ..
mkdir -p dist pkg/DEBIAN pkg/usr/bin
cp upstream/target/release/pdfcraft upstream/target/release/pdfcraft-cli pkg/usr/bin/
python3 scripts/verify.py pkg/usr/bin/pdfcraft pkg/usr/bin/pdfcraft-cli
cat > pkg/DEBIAN/control <<'EOF'
Package: pdfcraft-kylin
Version: 0.21.1-1
Architecture: arm64
Maintainer: Community Build <noreply@users.noreply.github.com>
Depends: libc6 (>= 2.31)
Description: PDFCraft ARM64 compatibility build for Kylin
EOF
dpkg-deb --build --root-owner-group pkg dist/pdfcraft-kylin_0.21.1-1_arm64.deb
tar -czf dist/pdfcraft-kylin_0.21.1_arm64.tar.gz -C pkg/usr/bin .
(cd dist && sha256sum *.deb *.tar.gz > SHA256SUMS)
