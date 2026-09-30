set(SOURCE_PATH "C:/Users/Admin/source/repos/brazier")

if(NOT EXISTS "${SOURCE_PATH}")
    message(FATAL_ERROR "Source directory not found: ${SOURCE_PATH}")
endif()

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}/brazier"
    OPTIONS -DBUILD_TESTS=OFF  
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH share/brazier)

file(REMOVE_RECURSE 
    "${CURRENT_PACKAGES_DIR}/debug/include"
    "${CURRENT_PACKAGES_DIR}/debug/share"
)

if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(REMOVE_RECURSE 
        "${CURRENT_PACKAGES_DIR}/bin"
        "${CURRENT_PACKAGES_DIR}/debug/bin"
    )
endif()

set(VCPKG_POLICY_DLLS_WITHOUT_EXPORTS enabled)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")