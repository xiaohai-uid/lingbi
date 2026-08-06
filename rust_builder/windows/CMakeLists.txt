# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "lingbi_ffi")
project(${PROJECT_NAME} LANGUAGES CXX)

file(MAKE_DIRECTORY
  "${CMAKE_CURRENT_BINARY_DIR}/Debug"
  "${CMAKE_CURRENT_BINARY_DIR}/Profile"
  "${CMAKE_CURRENT_BINARY_DIR}/Release"
)

include("../cargokit/cmake/cargokit.cmake")
# CI can point LINGBI_RUST_CRATE_DIR at a Windows-accessible crate copy.
if(DEFINED ENV{LINGBI_RUST_CRATE_DIR})
    set(LINGBI_RUST_MANIFEST_DIR "$ENV{LINGBI_RUST_CRATE_DIR}")
else()
    set(LINGBI_RUST_MANIFEST_DIR "../../../../../../../lingbi-next/crates/lingbi-ffi")
endif()
apply_cargokit(${PROJECT_NAME} "${LINGBI_RUST_MANIFEST_DIR}" lingbi_ffi "")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(lingbi_ffi_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
