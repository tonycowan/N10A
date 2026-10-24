#!/usr/bin/env bash
# Download a pinned unsigned Optio matrix from tonycowan/Prns Actions runs.
set -euo pipefail

: "${GH_TOKEN:?PRNS_ACTIONS_TOKEN is not set}"
: "${PRNS_SHA:?prns_sha is required}"
: "${MACOS_RUN_ID:?macos_run_id is required}"
: "${LINUX_RUN_ID:?linux_run_id is required}"
: "${WINDOWS_RUN_ID:?windows_run_id is required}"
: "${ANDROID_RUN_ID:?android_run_id is required}"

repo="tonycowan/Prns"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
out="$root/unsigned"
rm -rf "$out"
mkdir -p "$out"

fetch_one() {
    local platform="$1"
    local run_id="$2"
    local artifact="$3"
    local archive="$4"
    local dest="$out/$platform"

    local head conclusion name
    head="$(gh run view "$run_id" --repo "$repo" --json headSha --jq .headSha)"
    conclusion="$(gh run view "$run_id" --repo "$repo" --json conclusion --jq .conclusion)"
    name="$(gh run view "$run_id" --repo "$repo" --json name --jq .name)"

    if [[ "$head" != "$PRNS_SHA" ]]; then
        echo "error: $platform run $run_id is $head, not pinned $PRNS_SHA" >&2
        exit 1
    fi
    if [[ "$conclusion" != "success" ]]; then
        echo "error: $platform run $run_id conclusion is $conclusion" >&2
        exit 1
    fi
    case "$name" in
        optio-macos-package|optio-linux-package|optio-windows-package|optio-android-package) ;;
        *)
            echo "error: $platform run $run_id is workflow '$name', not an Optio package" >&2
            exit 1
            ;;
    esac

    mkdir -p "$dest"
    gh run download "$run_id" --repo "$repo" --name "$artifact" --dir "$dest"
    if [[ ! -f "$dest/$archive" ]]; then
        echo "error: $dest/$archive missing after download" >&2
        exit 1
    fi
}

fetch_one macos "$MACOS_RUN_ID" Optio-macos-aarch64-unsigned Optio-macos-aarch64-unsigned.zip
fetch_one macos "$MACOS_RUN_ID" Optio-macos-x86_64-unsigned Optio-macos-x86_64-unsigned.zip
fetch_one linux "$LINUX_RUN_ID" Optio-linux-aarch64-unsigned Optio-linux-aarch64-unsigned.tar.gz
fetch_one linux "$LINUX_RUN_ID" Optio-linux-x86_64-unsigned Optio-linux-x86_64-unsigned.tar.gz
fetch_one windows "$WINDOWS_RUN_ID" Optio-windows-aarch64-unsigned Optio-windows-aarch64-unsigned.zip
fetch_one windows "$WINDOWS_RUN_ID" Optio-windows-x86_64-unsigned Optio-windows-x86_64-unsigned.zip
fetch_one android "$ANDROID_RUN_ID" Optio-android-aarch64-unsigned Optio-android-aarch64-unsigned.apk

require_size() {
    local path="$1"
    local size
    size="$(wc -c <"$path" | tr -d ' ')"
    if [[ "$size" -lt 1000000 ]]; then
        echo "error: $path is only $size bytes" >&2
        exit 1
    fi
    echo "$path: $size bytes"
}

require_size "$out/macos/Optio-macos-aarch64-unsigned.zip"
require_size "$out/macos/Optio-macos-x86_64-unsigned.zip"
require_size "$out/linux/Optio-linux-aarch64-unsigned.tar.gz"
require_size "$out/linux/Optio-linux-x86_64-unsigned.tar.gz"
require_size "$out/windows/Optio-windows-aarch64-unsigned.zip"
require_size "$out/windows/Optio-windows-x86_64-unsigned.zip"
require_size "$out/android/Optio-android-aarch64-unsigned.apk"

echo "unsigned desktop six-way + Android aarch64 match $PRNS_SHA"
