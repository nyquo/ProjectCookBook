pragma Singleton

import QtQuick
import Plating

// What the toolbar switches, live; the window's snackbar
QtObject {
    id: state

    // Starts from the system's color scheme
    property bool dark: false
    property int accent: UiTheme.Raspberry
    property bool reducedMotion: false

    // Set by Main
    property Snackbar snackbar
    // What the snackbar's action does
    property var onAction: null

    // Shows a message; `undo`, if given, runs when the user taps Undo
    function notify(message: string, undo: var) {
        state.onAction = undo ?? null
        state.snackbar.show(message, undo ? qsTr("Undo") : "")
    }

    function runAction() {
        const action = state.onAction
        state.onAction = null
        if (action)
            action()
    }

    Component.onCompleted: state.dark = Application.styleHints.colorScheme === Qt.ColorScheme.Dark
}
