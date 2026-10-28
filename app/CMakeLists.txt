qt_add_executable(appProjectCookbook
    main.cpp
)

set_source_files_properties(
    AisleColors.qml
    ErrorTexts.qml
    TagFamilies.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(appProjectCookbook
    URI ProjectCookbook
    # Also gives qmlcachegen the modules' import paths, so it compiles typed code
    DEPENDENCIES TARGET plating TARGET cookbookui
    QML_FILES
        Main.qml
        AisleColors.qml
        AislesSheet.qml
        AppScreen.qml
        CatalogItemSheet.qml
        CatalogScreen.qml
        ErrorTexts.qml
        HomeScreen.qml
        RecipeScreen.qml
        ScreenStack.qml
        SettingsScreen.qml
        StartupError.qml
        TabPage.qml
        TagFamilies.qml
        TagsScreen.qml
    SOURCES
        AisleListModel.hpp AisleListModel.cpp
        AmountFormat.hpp AmountFormat.cpp
        appBackend.hpp appBackend.cpp
        AppearanceSettings.hpp AppearanceSettings.cpp
        AppInfo.hpp AppInfo.cpp
        CatalogListModel.hpp CatalogListModel.cpp
        collation.hpp collation.cpp
        CookingSettings.hpp CookingSettings.cpp
        DefaultFilterSettings.hpp DefaultFilterSettings.cpp
        KeepScreenOn.hpp KeepScreenOn.cpp
        Overloaded.hpp
        PhotoStore.hpp PhotoStore.cpp
        RecipeFieldSettings.hpp RecipeFieldSettings.cpp
        RecipeListModel.hpp RecipeListModel.cpp
        RecipeModel.hpp RecipeModel.cpp
        RowListModel.hpp RowListModel.cpp
        sampleRecipes.hpp sampleRecipes.cpp
        TagColorListModel.hpp TagColorListModel.cpp
        TagListModel.hpp TagListModel.cpp
        UnitSettings.hpp UnitSettings.cpp
)

# The texts are written in English. i18n/projectcookbook_en.ts only gives the
# English plural forms of the texts that take a count (%n): "1 piece",
# "6 pieces". After adding or changing such a text, run the
# update_translations target, then fill in the new forms in that file.
qt_add_translations(appProjectCookbook
    SOURCE_TARGETS appProjectCookbook cookbookui
    TS_FILE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/i18n"
    TS_FILE_BASE projectcookbook
)

cookbook_set_warnings(appProjectCookbook)

target_compile_definitions(appProjectCookbook PRIVATE
    APP_DISPLAY_NAME="${APP_DISPLAY_NAME}"
    APP_VERSION="${PROJECT_VERSION}"
)

# The plugin targets too: Plating and CookbookUi are static QML modules (see
# main.cpp)
target_link_libraries(appProjectCookbook PRIVATE
    core plating platingplugin cookbookui cookbookuiplugin
    Qt6::Quick Qt6::QuickControls2 Qt6::Svg
)

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
