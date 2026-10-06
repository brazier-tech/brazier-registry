vcpkg_cmake_configure(
    SOURCE_PATH "${CMAKE_CURRENT_LIST_DIR}/source/brazier"
    OPTIONS
        -DBUILD_TESTS=OFF
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(
    PACKAGE_NAME brazier-core
    CONFIG_PATH share/brazier-core
)

file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)


file(GLOB LICENSE_FILES
    "${CMAKE_CURRENT_LIST_DIR}/source/LICENSE*"
    "${CMAKE_CURRENT_LIST_DIR}/source/COPYING*"
    "${CMAKE_CURRENT_LIST_DIR}/source/*.txt"
)

vcpkg_install_copyright(FILE_LIST ${LICENSE_FILES})