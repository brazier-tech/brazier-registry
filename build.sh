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

make_symlink() {
    local link="$1"; local target="$2"
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
        return
    fi
    rm -rf "$link"
    ln -s "$target" "$link"
    echo "Created symlink: $link -> $target"
}

copy_licenses() {
    local src="$1"; local dst="$2"
    mkdir -p "$dst"
    shopt -s nullglob
    for f in "$src"/LICENSE* "$src"/COPYING* "$src"/LGPL*.txt "$src"/GPL*.txt; do
        cp -f "$f" "$dst/"
        echo "Copied license: $(basename "$f")"
    done
    shopt -u nullglob
}

# Vcpkg hashes all files in the port dir; overwriting this marker forces
# a new ABI hash on every run, so ports are rebuilt from current sources.
# We use >> / overwrite semantics: the file always contains a single line.
touch_marker() {
    local port_dir="$1"
    if [ ! -d "$port_dir" ]; then
        echo "Warning: port dir not found: $port_dir"
        return
    fi
    # Nanoseconds guarantee uniqueness even on very fast consecutive runs.
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$(date '+%N')" \
        > "$port_dir/_abi_marker.txt"
    echo "Touched ABI marker: $port_dir/_abi_marker.txt"
}

clean_port() {
    local port="$1"
    echo "Cleaning $port..."
    rm -rf "$VCPKG_PATH/buildtrees/$port"
    rm -rf "$VCPKG_PATH/packages/${port}_x64-windows"
    rm -rf "$VCPKG_PATH/packages/${port}_x64-windows-dbg"
    rm -rf "$VCPKG_PATH/packages/${port}_x64-windows-rel"
}

clean_archives() {
    echo "Cleaning brazier archives..."
    for cache_dir in \
        "${HOME}/.cache/vcpkg/archives" \
        "${HOME}/.vcpkg/archives" \
        "${VCPKG_PATH}/archives"
    do
        if [ -d "$cache_dir" ]; then
            find "$cache_dir" -type f -name "*brazier*" -delete 2>/dev/null || true
        fi
    done
}

# --- symlinks ---
make_symlink "${PORTS_PATH}/brazier-core/source"   "${SOURCES_DIR}/brazier"
make_symlink "${PORTS_PATH}/brazier-orm/source"    "${SOURCES_DIR}/brazierORM"
make_symlink "${PORTS_PATH}/brazier-logger/source" "${SOURCES_DIR}/brazier-logger"

# --- licenses ---
copy_licenses "${SOURCES_DIR}/brazier"        "${PORTS_PATH}/brazier"
copy_licenses "${SOURCES_DIR}/brazier"        "${PORTS_PATH}/brazier-core"
copy_licenses "${SOURCES_DIR}/brazierORM"     "${PORTS_PATH}/brazier-orm"
copy_licenses "${SOURCES_DIR}/brazier-logger" "${PORTS_PATH}/brazier-logger"

# --- helpers ---
"$VCPKG_PATH/vcpkg" install vcpkg-cmake vcpkg-cmake-config --recurse

# --- invalidate ABI hash so vcpkg rebuilds from current sources ---
touch_marker "${PORTS_PATH}/brazier"
touch_marker "${PORTS_PATH}/brazier-core"
touch_marker "${PORTS_PATH}/brazier-orm"
touch_marker "${PORTS_PATH}/brazier-logger"

# --- full clean for each brazier port ---
clean_archives
clean_port brazier
clean_port brazier-core
clean_port brazier-orm
clean_port brazier-logger

# --- remove old installs ---
"$VCPKG_PATH/vcpkg" remove brazier-logger:x64-windows --recurse --purge
"$VCPKG_PATH/vcpkg" remove brazier-orm:x64-windows    --recurse --purge
"$VCPKG_PATH/vcpkg" remove brazier-core:x64-windows   --recurse --purge
"$VCPKG_PATH/vcpkg" remove brazier:x64-windows        --recurse --purge

# --- install all brazier packages in one plan ---
"$VCPKG_PATH/vcpkg" install --overlay-ports="$PORTS_PATH" \
    brazier --recurse --editable --no-binarycaching