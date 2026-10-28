# The showcase: every Plating and CookbookUi component in its variants and
# states, for desktop and Android. Links no core.
qt_add_executable(showcase
    main.cpp
)

set_source_files_properties(
    ShowcaseState.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

qt_add_qml_module(showcase
    URI Showcase
    DEPENDENCIES TARGET plating TARGET cookbookui
    QML_FILES
        Main.qml
        ShowcaseState.qml
        ShowcaseBar.qml
        PageEntry.qml
        HomePage.qml
        GroupPage.qml
        Specimen.qml
        pages/ActionsPage.qml
        pages/CatalogPage.qml
        pages/DisplayPage.qml
        pages/IngredientsPage.qml
        pages/StructurePage.qml
        pages/InputsPage.qml
        pages/OverlaysPage.qml
        pages/QuantitiesPage.qml
        pages/RecipesPage.qml
        pages/ShoppingPage.qml
    # A stand-in photo
    RESOURCES
        images/gratin.svg
    SOURCES
        WindowCapture.hpp WindowCapture.cpp
)

# The generated type registration includes <WindowCapture.hpp> by its bare name
target_include_directories(showcase PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
cookbook_set_warnings(showcase)

# The plugin targets too: Plating and CookbookUi are static QML modules (see
# main.cpp)
target_link_libraries(showcase PRIVATE
    plating platingplugin cookbookui cookbookuiplugin
    Qt6::Quick Qt6::QuickControls2 Qt6::Svg
)

set_target_properties(showcase PROPERTIES
    QT_ANDROID_PACKAGE_NAME "${APP_ANDROID_PACKAGE}.showcase"
    QT_ANDROID_APP_NAME "Showcase"
    QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
    QT_ANDROID_VERSION_CODE "${APP_ANDROID_VERSION_CODE}"
    QT_ANDROID_MIN_SDK_VERSION 28
    QT_ANDROID_TARGET_SDK_VERSION 36
)
