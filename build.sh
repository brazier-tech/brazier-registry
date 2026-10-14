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

# --- target selection ---
TARGET="${1:-brazier}"

case "$TARGET" in
    brazier|brazier-core|brazier-orm|brazier-logger) ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Valid: brazier | brazier-core | brazier-orm | brazier-logger"
        exit 1
        ;;
esac
echo "=== Target: $TARGET ==="

resolve_ref() {
    local name="$1" url="$2" var_name=""
    case "$name" in
        brazier-logger) var_name="BRAZIER_LOGGER_REF_DEFAULT" ;;
        brazier-core)   var_name="BRAZIER_CORE_REF_DEFAULT" ;;
        brazier-orm)    var_name="BRAZIER_ORM_REF_DEFAULT" ;;
        *) return ;;
    esac
    local sha
    sha=$(git ls-remote "$url" refs/heads/master 2>/dev/null | awk '{print $1}' | head -1)
    [ -z "$sha" ] && return
    printf 'set(%s "%s")\n' "$var_name" "$sha" > "${PORTS_PATH}/${name}/_resolved_ref.cmake"
    echo "[resolve] $name: $sha"
}

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

touch_marker() {
    local port_dir="$1"
    if [ ! -d "$port_dir" ]; then
        echo "Warning: port dir not found: $port_dir"
        return
    fi
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
make_symlink "${PORTS_PATH}/brazier-orm/source"    "${SOURCES_DIR}/brazier-orm"
make_symlink "${PORTS_PATH}/brazier-logger/source" "${SOURCES_DIR}/brazier-logger"

# --- licenses ---
copy_licenses "${SOURCES_DIR}/brazier"        "${PORTS_PATH}/brazier"
copy_licenses "${SOURCES_DIR}/brazier"        "${PORTS_PATH}/brazier-core"
copy_licenses "${SOURCES_DIR}/brazier-orm"     "${PORTS_PATH}/brazier-orm"
copy_licenses "${SOURCES_DIR}/brazier-logger" "${PORTS_PATH}/brazier-logger"

# --- resolve upstream REFs ---
resolve_ref "brazier-logger" "https://github.com/brazier-tech/brazier-logger.git"
resolve_ref "brazier-core"   "https://github.com/brazier-tech/brazier.git"
resolve_ref "brazier-orm"    "https://github.com/brazier-tech/brazier-orm.git"

# --- helpers ---
"$VCPKG_PATH/vcpkg" install vcpkg-cmake vcpkg-cmake-config --recurse

# --- invalidate ABI hash ---
if [ "$TARGET" = "brazier" ]; then
    touch_marker "${PORTS_PATH}/brazier"
    touch_marker "${PORTS_PATH}/brazier-core"
    touch_marker "${PORTS_PATH}/brazier-orm"
    touch_marker "${PORTS_PATH}/brazier-logger"
else
    touch_marker "${PORTS_PATH}/${TARGET}"
fi

# --- clean + remove ---
if [ "$TARGET" = "brazier" ]; then
    clean_archives
    clean_port brazier
    clean_port brazier-core
    clean_port brazier-orm
    clean_port brazier-logger

    "$VCPKG_PATH/vcpkg" remove brazier-logger:x64-windows --recurse --purge 2>/dev/null || true
    "$VCPKG_PATH/vcpkg" remove brazier-orm:x64-windows    --recurse --purge 2>/dev/null || true
    "$VCPKG_PATH/vcpkg" remove brazier-core:x64-windows   --recurse --purge 2>/dev/null || true
    "$VCPKG_PATH/vcpkg" remove brazier:x64-windows        --recurse --purge 2>/dev/null || true
else
    clean_port "$TARGET"
    "$VCPKG_PATH/vcpkg" remove "${TARGET}:x64-windows" --recurse --purge 2>/dev/null || true
fi

# --- install ---
"$VCPKG_PATH/vcpkg" install --overlay-ports="$PORTS_PATH" \
    "$TARGET" --recurse --editable --no-binarycaching