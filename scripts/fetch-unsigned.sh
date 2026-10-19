#!/usr/bin/env bash
# Download a pinned unsigned TouchBase matrix from tonycowan/Prns Actions runs.
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
        touchbase-macos-package|touchbase-linux-package|touchbase-windows-package|touchbase-android-package) ;;
        *)
            echo "error: $platform run $run_id is workflow '$name', not a TouchBase package" >&2
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

fetch_one macos "$MACOS_RUN_ID" TouchBase-macos-aarch64-unsigned TouchBase-macos-aarch64-unsigned.zip
fetch_one macos "$MACOS_RUN_ID" TouchBase-macos-x86_64-unsigned TouchBase-macos-x86_64-unsigned.zip
fetch_one linux "$LINUX_RUN_ID" TouchBase-linux-aarch64-unsigned TouchBase-linux-aarch64-unsigned.tar.gz
fetch_one linux "$LINUX_RUN_ID" TouchBase-linux-x86_64-unsigned TouchBase-linux-x86_64-unsigned.tar.gz
fetch_one windows "$WINDOWS_RUN_ID" TouchBase-windows-aarch64-unsigned TouchBase-windows-aarch64-unsigned.zip
fetch_one windows "$WINDOWS_RUN_ID" TouchBase-windows-x86_64-unsigned TouchBase-windows-x86_64-unsigned.zip
fetch_one android "$ANDROID_RUN_ID" TouchBase-android-aarch64-unsigned TouchBase-android-aarch64-unsigned.apk

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

require_size "$out/macos/TouchBase-macos-aarch64-unsigned.zip"
require_size "$out/macos/TouchBase-macos-x86_64-unsigned.zip"
require_size "$out/linux/TouchBase-linux-aarch64-unsigned.tar.gz"
require_size "$out/linux/TouchBase-linux-x86_64-unsigned.tar.gz"
require_size "$out/windows/TouchBase-windows-aarch64-unsigned.zip"
require_size "$out/windows/TouchBase-windows-x86_64-unsigned.zip"
require_size "$out/android/TouchBase-android-aarch64-unsigned.apk"

echo "unsigned desktop six-way + Android aarch64 match $PRNS_SHA"
