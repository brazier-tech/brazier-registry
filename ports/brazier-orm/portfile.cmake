# SPDX-License-Identifier: LGPL-3.0-or-later

if(DEFINED ENV{BRAZIER_ORM_REF} AND NOT "$ENV{BRAZIER_ORM_REF}" STREQUAL "")
    set(BRAZIER_ORM_REF "$ENV{BRAZIER_ORM_REF}")
else()
    set(BRAZIER_ORM_REF "master")
endif()

message(STATUS "brazier-orm: REF = ${BRAZIER_ORM_REF}")

if(EXISTS "${CMAKE_CURRENT_LIST_DIR}/source/brazierORM/CMakeLists.txt")
    message(STATUS "brazier-orm: using LOCAL source (editable mode)")
    set(SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/source/brazierORM")
else()
    message(STATUS "brazier-orm: cloning from git (ref=${BRAZIER_ORM_REF})")
    vcpkg_from_git(
        OUT_SOURCE_PATH GIT_SOURCE
        URL https://github.com/brazier-tech/brazierORM.git
        REF ${BRAZIER_ORM_REF}
        HEAD_REF master
    )
    set(SOURCE_PATH "${GIT_SOURCE}/brazierORM")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=OFF
        -DBUILD_DEMO=OFF
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME brazier-orm
    CONFIG_PATH share/brazier-orm
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

file(GLOB LICENSE_FILES
    "${SOURCE_PATH}/LICENSE*"
    "${SOURCE_PATH}/COPYING*"
    "${SOURCE_PATH}/LGPL*.txt"
    "${SOURCE_PATH}/GPL*.txt"
)

vcpkg_install_copyright(FILE_LIST ${LICENSE_FILES})