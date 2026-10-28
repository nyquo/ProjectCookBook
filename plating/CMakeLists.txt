# Plating: the app's Qt Quick Controls style, design tokens and generic
# components. Never links or includes core or the app's components (see the
# guards in the root CMakeLists.txt).
qt_add_library(plating STATIC)

set_source_files_properties(
    theme/DefaultLightTheme.qml
    theme/DefaultDarkTheme.qml
    theme/UiMetrics.qml
    theme/UiMotion.qml
    theme/UiTypography.qml
    icons/UiIcons.qml
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
        theme/UiMotion.qml
        theme/UiTypography.qml
        icons/Icon.qml
        icons/UiIcons.qml
        parts/DashedOutline.qml
        parts/FocusRing.qml
        parts/MenuPanel.qml
        parts/PressOverlay.qml
        parts/RaisedShadow.qml
        parts/TouchTarget.qml
        utils/UiScaler.qml
        controls/ApplicationWindow.qml
        controls/BottomNav.qml
        controls/BottomNavItem.qml
        controls/BottomSheet.qml
        controls/Button.qml
        controls/CheckBox.qml
        controls/ChoiceChip.qml
        controls/ColorSwatch.qml
        controls/ComboBox.qml
        controls/EmptyState.qml
        controls/FilterChip.qml
        controls/FloatingActionButton.qml
        controls/IconBadge.qml
        controls/IconButton.qml
        controls/InputChip.qml
        controls/ListGroup.qml
        controls/ListRow.qml
        controls/Menu.qml
        controls/MenuItem.qml
        controls/MenuSeparator.qml
        controls/Page.qml
        controls/ScreenHeader.qml
        controls/ScrollArea.qml
        controls/SearchField.qml
        controls/SectionHeader.qml
        controls/SegmentedButton.qml
        controls/SegmentedControl.qml
        controls/Snackbar.qml
        controls/SpecStrip.qml
        controls/SplitBar.qml
        controls/Stepper.qml
        controls/Switch.qml
        controls/TagChip.qml
        controls/TagPill.qml
        controls/TextArea.qml
        controls/TextField.qml
        controls/Thumbnail.qml
        controls/TitleField.qml
    SOURCES
        theme/ColorFamily.hpp
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
