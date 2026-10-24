#!/usr/bin/env bash
# Stage the archives that a GitHub Release should attach.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dist="$root/dist"
rm -rf "$dist"
mkdir -p "$dist"

cp "$root"/unsigned/linux/Optio-linux-*-unsigned.tar.gz "$dist/"
cp "$root"/unsigned/windows/Optio-windows-*-unsigned.zip "$dist/"
cp "$root"/unsigned/android/Optio-android-*-unsigned.apk "$dist/"

shopt -s nullglob
signed=( "$root"/unsigned/macos/Optio-macos-aarch64.zip \
         "$root"/unsigned/macos/Optio-macos-x86_64.zip )
if [[ ${#signed[@]} -eq 2 && -f "${signed[0]}" && -f "${signed[1]}" ]]; then
    cp "${signed[@]}" "$dist/"
else
    cp "$root"/unsigned/macos/Optio-macos-*-unsigned.zip "$dist/"
fi
shopt -u nullglob

(
    cd "$dist"
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 -- * >SHA256SUMS
    else
        sha256sum -- * >SHA256SUMS
    fi
)
echo "staged $(ls "$dist" | tr '\n' ' ')"
