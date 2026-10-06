cmake_minimum_required(VERSION 3.25)

project(ProjectCookbook VERSION 0.1.0 LANGUAGES CXX)

# -----------------------------------------------------------------------------
# App identity. "Project Cookbook" is a working title: when the real name is
# decided, change it here (see "Renaming the app" in README.md).
# -----------------------------------------------------------------------------
set(APP_DISPLAY_NAME "Project Cookbook")
# Android application id. Must be a reverse-domain name you control before
# publishing (Google Play rejects com.example.*).
set(APP_ANDROID_PACKAGE "com.example.projectcookbook")
# Must increase for every build uploaded to a store.
set(APP_ANDROID_VERSION_CODE 1)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Qt loads the CMake package of every QML plugin it ships. On Android builds the
# Qt GRPC/Protobuf ones then look for a host 'protoc' and print pages of
# warnings. This app doesn't use them; remove these lines if that changes.
set(CMAKE_DISABLE_FIND_PACKAGE_Qt6GrpcQuick ON)
set(CMAKE_DISABLE_FIND_PACKAGE_Qt6ProtobufQuick ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

add_subdirectory(src)
