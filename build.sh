#!/bin/bash
set -e

if [ -n "$VCPKG_ROOT" ]; then
    VCPKG_PATH="$VCPKG_ROOT"
else
    VCPKG_PATH="/tools/vcpkg"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PORTS_PATH="${SCRIPT_DIR}/ports"

echo "Using vcpkg from: $VCPKG_PATH"
echo "Ports path: $PORTS_PATH"

# --- create symlinks for source directories ---
make_symlink() {
    local link="$1"
    local target="$2"

    if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        echo "Symlink already correct: $link -> $target"
        return
    fi

    rm -rf "$link"
    ln -s "$target" "$link"
    echo "Created symlink: $link -> $target"
}

make_symlink "${PORTS_PATH}/brazier-core/source" "${SOURCES_DIR}/brazier"
make_symlink "${PORTS_PATH}/brazier-orm/source"  "${SOURCES_DIR}/brazierORM"

# --- copy license files into ports ---
copy_licenses() {
    local src="$1"
    local dst="$2"

    mkdir -p "$dst"

    shopt -s nullglob
    for f in "$src"/LICENSE* "$src"/COPYING* "$src"/LGPL*.txt "$src"/GPL*.txt; do
        cp -f "$f" "$dst/"
        echo "Copied license: $(basename "$f")"
    done
    shopt -u nullglob
}

copy_licenses "${SOURCES_DIR}/brazier"    "${PORTS_PATH}/brazier"
copy_licenses "${SOURCES_DIR}/brazier"    "${PORTS_PATH}/brazier-core"
copy_licenses "${SOURCES_DIR}/brazierORM" "${PORTS_PATH}/brazier-orm"

# --- ensure vcpkg helper ports are installed ---
"$VCPKG_PATH/vcpkg" install vcpkg-cmake vcpkg-cmake-config --recurse

# --- clean cache for rebuild ---
rm -rf "$VCPKG_PATH/packages/brazier_x64-windows" 2>/dev/null || true
rm -rf "$VCPKG_PATH/buildtrees/brazier" 2>/dev/null || true
rm -rf "$VCPKG_PATH/packages/brazier-core_x64-windows" 2>/dev/null || true
rm -rf "$VCPKG_PATH/buildtrees/brazier-core" 2>/dev/null || true
rm -rf "$VCPKG_PATH/packages/brazier-orm_x64-windows" 2>/dev/null || true
rm -rf "$VCPKG_PATH/buildtrees/brazier-orm" 2>/dev/null || true

# --- remove old installs ---
"$VCPKG_PATH/vcpkg" remove brazier-orm:x64-windows  --recurse --purge
"$VCPKG_PATH/vcpkg" remove brazier-core:x64-windows --recurse --purge
"$VCPKG_PATH/vcpkg" remove brazier:x64-windows      --recurse --purge

# --- install ---
"$VCPKG_PATH/vcpkg" install --overlay-ports="$PORTS_PATH" brazier --recurse --editable --no-binarycaching