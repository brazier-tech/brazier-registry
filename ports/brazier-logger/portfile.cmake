# SPDX-License-Identifier: LGPL-3.0-or-later

if(DEFINED ENV{BRAZIER_LOGGER_REF} AND NOT "$ENV{BRAZIER_LOGGER_REF}" STREQUAL "")
    set(BRAZIER_LOGGER_REF "$ENV{BRAZIER_LOGGER_REF}")
else()
    set(BRAZIER_LOGGER_REF "master")
endif()

message(STATUS "brazier-logger: REF = ${BRAZIER_LOGGER_REF}")

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/source/CMakeLists.txt")
    message(STATUS "brazier-logger: using LOCAL source (editable mode)")
    set(SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/source")
else()
    message(STATUS "brazier-logger: cloning from git (ref=${BRAZIER_LOGGER_REF})")
    vcpkg_from_git(
        OUT_SOURCE_PATH SOURCE_PATH
        URL https://github.com/brazier-tech/brazier-logger.git
        REF ${BRAZIER_LOGGER_REF}
        HEAD_REF master
    )
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
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