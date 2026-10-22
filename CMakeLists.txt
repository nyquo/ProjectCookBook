cmake_minimum_required(VERSION 3.25)

project(ProjectCookbook VERSION 0.1.0 LANGUAGES C CXX)

# -----------------------------------------------------------------------------
# App identity. "Project Cookbook" is a working title: when the real name is
# decided, change it here (see "Renaming the app" in README.md).
# -----------------------------------------------------------------------------
set(APP_DISPLAY_NAME "Project Cookbook")
# Android application id. Must be a reverse-domain name you control before
# publishing (Google Play rejects com.example.*).
set(APP_ANDROID_PACKAGE "com.example.projectcookbook")
# Must increase for every build uploaded to a store
set(APP_ANDROID_VERSION_CODE 1)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# MSVC otherwise reads sources in the system code page and mangles UTF-8 literals
add_compile_options($<$<CXX_COMPILER_ID:MSVC>:/utf-8>)

option(COOKBOOK_BUILD_APP "Build the Qt app. OFF builds only the core and its tests, without Qt." ON)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
include(Warnings)

# The core comes before Qt is even looked for: it must build without it
add_subdirectory(third_party/sqlite)
add_subdirectory(core)

if(NOT ANDROID)
    enable_testing()
    add_subdirectory(third_party/doctest)
    add_subdirectory(core/tests)
endif()

if(COOKBOOK_BUILD_APP)
    # Qt loads the CMake package of every QML plugin it ships. On Android builds the
    # Qt GRPC/Protobuf ones then look for a host 'protoc' and print pages of
    # warnings. This app doesn't use them; remove these lines if that changes.
    set(CMAKE_DISABLE_FIND_PACKAGE_Qt6GrpcQuick ON)
    set(CMAKE_DISABLE_FIND_PACKAGE_Qt6ProtobufQuick ON)

    find_package(Qt6 6.10 REQUIRED COMPONENTS Quick QuickControls2)

    qt_standard_project_setup(REQUIRES 6.10)
    # One folder for every QML module, so qmllint and qmlcachegen find Plating
    # from the app's QML.
    set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

    add_subdirectory(plating)
    add_subdirectory(app)

    get_target_property(platingLinks plating LINK_LIBRARIES)
    if("${platingLinks}" MATCHES "(^|;)core(;|$)")
        message(FATAL_ERROR "Plating must not link the core library (links: ${platingLinks})")
    endif()
endif()

get_target_property(coreLinks core LINK_LIBRARIES)
get_target_property(coreInterfaceLinks core INTERFACE_LINK_LIBRARIES)
if("${coreLinks};${coreInterfaceLinks}" MATCHES "Qt")
    message(FATAL_ERROR "The core library must not link Qt (links: ${coreLinks};${coreInterfaceLinks})")
endif()
