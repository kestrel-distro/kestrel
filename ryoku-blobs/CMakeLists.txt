# Ryoku.Blobs: the metaball QML module behind Ryoku's liquid bar (BlobGroup,
# BlobRect, BlobWave, BlobInvertedRect). Vendored from Ryoku (GPL-3.0, see the
# NOTICE at the repo root) minus the Stage-only types, so the module needs
# only Qt Quick and ShaderTools: no Quick3D, no Multimedia.
#
# Build on the package/ISO build host and ship the output prebuilt under a QML
# import path (Kestrel looks for modules under <config>/Ryoku/*, i.e.
# /usr/share/kestrel/shell/Ryoku/Blobs):
#
#   cmake -S ryoku-blobs -B build/ryoku-blobs -DCMAKE_BUILD_TYPE=Release
#   cmake --build build/ryoku-blobs
#   cmake --install build/ryoku-blobs --prefix /usr/share/kestrel
#
# The module is relocatable ($ORIGIN rpath): copy the directory onto any QML
# import path and it loads.
cmake_minimum_required(VERSION 3.28)

project(kestrel-ryoku-blobs LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick ShaderTools)
find_package(Threads REQUIRED)

qt_standard_project_setup(REQUIRES 6.5)

qt_add_qml_module(kestrel-ryoku-blobs
    URI Ryoku.Blobs
    VERSION 1.0
    OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/Ryoku/Blobs"
    SOURCES
        src/blobgroup.cpp src/blobgroup.hpp
        src/blobshape.cpp src/blobshape.hpp
        src/blobrect.cpp src/blobrect.hpp
        src/blobwave.cpp src/blobwave.hpp
        src/blobinvertedrect.cpp src/blobinvertedrect.hpp
        src/blobmaterial.cpp src/blobmaterial.hpp
)

target_include_directories(kestrel-ryoku-blobs PRIVATE src)
target_link_libraries(kestrel-ryoku-blobs PRIVATE Qt6::Quick Threads::Threads)

set_target_properties(kestrel-ryoku-blobs kestrel-ryoku-blobsplugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml/Ryoku/Blobs")
set_target_properties(kestrel-ryoku-blobsplugin PROPERTIES
    INSTALL_RPATH "$ORIGIN"
    BUILD_WITH_INSTALL_RPATH ON)

qt_add_shaders(kestrel-ryoku-blobs "blob_shaders"
    BATCHABLE
    GLSL "300es,330"
    PREFIX "/"
    FILES
        shaders/blob.vert
        shaders/blob.frag
)

install(DIRECTORY "${CMAKE_BINARY_DIR}/qml/Ryoku/Blobs" DESTINATION shell/Ryoku)
