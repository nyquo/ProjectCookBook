qt_add_executable(appProjectCookbook
    main.cpp
)

qt_add_qml_module(appProjectCookbook
    URI ProjectCookbook
    QML_FILES
        Main.qml
        AislesScreen.qml
    SOURCES
        AisleListModel.hpp AisleListModel.cpp
        appBackend.hpp appBackend.cpp
        AppInfo.hpp AppInfo.cpp
)

cookbook_set_warnings(appProjectCookbook)

target_compile_definitions(appProjectCookbook PRIVATE
    APP_DISPLAY_NAME="${APP_DISPLAY_NAME}"
    APP_VERSION="${PROJECT_VERSION}"
)

target_link_libraries(appProjectCookbook PRIVATE core Qt6::Quick)

set_target_properties(appProjectCookbook PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR "${PROJECT_SOURCE_DIR}/android"
    QT_ANDROID_PACKAGE_NAME "${APP_ANDROID_PACKAGE}"
    QT_ANDROID_APP_NAME "${APP_DISPLAY_NAME}"
    QT_ANDROID_APP_ICON "@mipmap/ic_launcher"
    QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
    QT_ANDROID_VERSION_CODE "${APP_ANDROID_VERSION_CODE}"
    QT_ANDROID_MIN_SDK_VERSION 28
    QT_ANDROID_TARGET_SDK_VERSION 36
)
