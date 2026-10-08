# SPDX-License-Identifier: LGPL-3.0-or-later

vcpkg_cmake_configure(
    SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/source"
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME brazier-logger
    CONFIG_PATH share/brazier-logger
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(GLOB LICENSE_FILES
    "${CMAKE_CURRENT_LIST_DIR}/LICENSE*"
    "${CMAKE_CURRENT_LIST_DIR}/COPYING*"
    "${CMAKE_CURRENT_LIST_DIR}/LGPL*.txt"
    "${CMAKE_CURRENT_LIST_DIR}/GPL*.txt"
)

vcpkg_install_copyright(FILE_LIST ${LICENSE_FILES})