pragma ComponentBehavior: Bound

import QtQuick
import Plating

ApplicationWindow {
    id: window

    // The theme's accent, from the setting
    readonly property int accentChoice: {
        switch (AppearanceSettings.accent) {
        case AppearanceSettings.Accent.Spirulina:
            return UiTheme.Spirulina
        case AppearanceSettings.Accent.Blueberry:
            return UiTheme.Blueberry
        case AppearanceSettings.Accent.Saffron:
            return UiTheme.Saffron
        case AppearanceSettings.Accent.Basil:
            return UiTheme.Basil
        default:
            return UiTheme.Raspberry
        }
    }

    // What the snackbar's action runs
    property var snackbarAction: null

    // Shows a message at the bottom of the window, with an optional action
    // ("Undo") that runs `action`
    function notify(message: string, actionText: string, action: var) {
        window.snackbarAction = action ?? null
        snackbar.show(message, actionText)
    }

    // A recipe screen deleted its recipe: it closes, and the recipes list
    // offers Undo. Here rather than in the screen, whose context the Undo
    // action would outlive.
    function recipeRemoved(recipeId: string, title: string) {
        stack.pop()
        window.notify(qsTr("%1 deleted").arg(title), qsTr("Undo"), () => home.restoreRecipe(recipeId))
    }

    // Phone-like size for desktop previews; ignored on Android (always fullscreen)
    width: 400
    height: 760
    visible: true
    title: AppInfo.name

    // Edge to edge: on Android the window goes under the status and navigation
    // bars, and each screen pads itself with SafeArea.
    flags: Qt.platform.os === "android" ? Qt.Window | Qt.ExpandedClientAreaHint : Qt.Window
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    // A forced theme doesn't depend on the platform honoring the color scheme
    // AppearanceSettings requests; System follows the system, live.
    Plating.theme: {
        switch (AppearanceSettings.themeMode) {
        case AppearanceSettings.ThemeMode.Light:
            return DefaultLightTheme
        case AppearanceSettings.ThemeMode.Dark:
            return DefaultDarkTheme
        default:
            return Application.styleHints.colorScheme === Qt.ColorScheme.Dark ? DefaultDarkTheme
                                                                               : DefaultLightTheme
        }
    }

    Binding {
        target: UiScaler
        property: "actualSize"
        value: Qt.size(window.width, window.height)
    }
    // The system's reduced motion preference
    Binding {
        target: UiMotion
        property: "reduced"
        value: Application.styleHints.accessibility.motionPreference === Qt.MotionPreference.ReducedMotion
    }
    Binding {
        target: DefaultLightTheme
        property: "accentChoice"
        value: window.accentChoice
    }
    Binding {
        target: DefaultDarkTheme
        property: "accentChoice"
        value: window.accentChoice
    }

    ScreenStack {
        id: stack

        anchors.fill: parent
        focus: true
        initialItem: HomeScreen {
            id: home

            onSettingsClicked: stack.push(settingsScreen)
            onRecipeClicked: recipeId => stack.push(recipeScreen, { recipeId: recipeId })
        }

        // A message's action acts on the screen that showed it, which a pop
        // destroys
        onCurrentItemChanged: {
            window.snackbarAction = null
            snackbar.close()
        }
    }

    Component {
        id: settingsScreen

        SettingsScreen {}
    }

    Component {
        id: recipeScreen

        RecipeScreen {
            onRemoved: (recipeId, title) => window.recipeRemoved(recipeId, title)
        }
    }

    // Over the sheets, which open later
    Snackbar {
        id: snackbar

        z: 2
        bottomOffset: (stack.currentItem as AppScreen)?.snackbarOffset ?? 0
        onActionClicked: {
            const action = window.snackbarAction
            window.snackbarAction = null
            if (action)
                action()
        }
    }
}
