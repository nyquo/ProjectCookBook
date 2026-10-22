# Plating: the app's Qt Quick Controls style and design tokens. Never links or
# includes core (see the guard in the root CMakeLists.txt).
qt_add_library(plating STATIC)

set_source_files_properties(
    theme/DefaultLightTheme.qml
    theme/DefaultDarkTheme.qml
    theme/UiMetrics.qml
    theme/UiTypography.qml
    utils/UiScaler.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(plating
    URI Plating
    # Controls Plating doesn't implement yet come from Basic
    IMPORTS QtQuick.Controls.Basic
    QML_FILES
        theme/UiTheme.qml
        theme/LightTheme.qml
        theme/DarkTheme.qml
        theme/DefaultLightTheme.qml
        theme/DefaultDarkTheme.qml
        theme/UiMetrics.qml
        theme/UiTypography.qml
        utils/UiScaler.qml
        controls/ApplicationWindow.qml
        controls/Page.qml
    SOURCES
        theme/Plating.hpp theme/Plating.cpp
    RESOURCES
        fonts/BricolageGrotesque-Variable.ttf
        fonts/OFL.txt
)

# The generated type registration includes <Plating.hpp> by its bare name
target_include_directories(plating PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/theme")
target_link_libraries(plating PRIVATE Qt6::Quick Qt6::QuickControls2)
# On Android it ends up inside the app's shared library
set_target_properties(plating platingplugin PROPERTIES POSITION_INDEPENDENT_CODE ON)
cookbook_set_warnings(plating)
