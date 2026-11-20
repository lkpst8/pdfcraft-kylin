# PdfCraft for Kylin V10 ARM64 (glibc 2.31)

Unofficial build recipe for PdfCraft v0.21.1 targeting **AArch64 / glibc 2.31**, intended for testing on air-gapped Kylin V10 SP1 workstations.

## Versions and source

- Upstream: [storytold/pdfcraft](https://github.com/storytold/pdfcraft), commit `b503b2e62dfeec5598f344e4e287d9c9cbdb34fa` (v0.21.1)
- Translations: `storytold/craft-i18n`, commit `575cfdef63227b14daf173b8cc87928bfdfa325e`
- Toolchain: Rust 1.95.0 on ARM64 Ubuntu 20.04 (glibc 2.31)
- Build runner: GitHub-hosted `ubuntu-24.04-arm` with Ubuntu 20.04 container

## Build and publish

Pushes to `main` run a build and upload an Actions artifact **if successful**. To publish to Releases, go to **Actions -> Build PdfCraft for Kylin ARM64 (glibc 2.31) -> Run workflow** and choose `publish_release=true`.

The workflow compiles the GUI and CLI, downloads SHA256-verified OCR model files, includes UI translations, creates `.deb` and `.tar.gz`, then checks ELF architecture and required GLIBC symbols. A build with any required GLIBC symbol newer than 2.31 fails.

The package metadata requires `libc6 (>= 2.31)` and selected graphics libraries. This check alone does not establish that all Kylin desktop graphics/runtime dependencies exist; the target device must be tested.

## Deploy with zero network access on Kylin

Download the successful Release files on an approved internet-connected device and move them to the isolated workstation using approved removable media.

On the target, confirm:

```bash
getconf GNU_LIBC_VERSION
uname -m
dpkg -l libc6 libgcc-s1 libxkbcommon0 libegl1 libvulkan1
```

Install the deb from the directory containing it:

```bash
sudo dpkg -i pdfcraft-0.21.1-kylin-glibc231-arm64.deb
pdfcraft --version
pdfcraft
```

Troubleshooting:

```bash
ldd /usr/bin/pdfcraft
PDFCRAFT_RENDERER=gl pdfcraft
```

If additional dependencies are missing, acquire *Kylin-compatible ARM64* packages through the organization's approved offline process. Avoid replacing the system libc6 or installing Ubuntu 20.04 system libc6 packages on Kylin.

The `.tar.gz` archive provides a manual staging alternative containing the `usr/` tree.

## Known constraints

- The builder can access the internet; the Kylin workstation never needs internet access.
- GitHub Actions results and a genuine desktop launch on Kylin determine readiness.
- The current ELF guard covers GLIBC symbols of the two executable files. Other dynamically loaded runtime files, GPU drivers, and runtime API calls may have separate requirements.
- This is a third-party build recipe, not an official PdfCraft binary.

Original code and artwork remain under the upstream project's applicable licences.
