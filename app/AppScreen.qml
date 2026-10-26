import QtQuick
import Plating
import CookbookUi

// A screen of the ScreenStack, on the bg color; its children fill it
FocusScope {
    id: screen

    readonly property UiTheme theme: Plating.theme as UiTheme

    // From 0 to 1 while a screen pushed over this one slides in; the
    // ScreenStack's transitions animate it
    property real dim: 0
    // What the snackbar keeps clear of at the bottom: the bottom bar, a
    // floating button
    property real snackbarOffset: 0
    // Asks to keep the display awake while this screen is on top, if the
    // user's Keep screen on setting allows it (a recipe being cooked)
    property bool keepScreenOn: false

    default property alias content: body.data

    // A message at the bottom of the window, with an optional action ("Undo")
    // that runs `action`
    function notify(message: string, actionText: string, action: var) {
        (screen.Window.window as Main)?.notify(message, actionText, action)
    }

    // Released as soon as another screen is pushed over this one
    KeepScreenOn {
        active: screen.keepScreenOn && (screen.StackView.status === StackView.Active
                                        || screen.StackView.status === StackView.Activating)
    }

    Rectangle {
        anchors.fill: parent
        color: screen.theme.bg
    }

    Item {
        id: body

        anchors.fill: parent
    }

    Rectangle {
        anchors.fill: parent
        visible: screen.dim > 0
        color: screen.theme.scrim
        opacity: screen.dim * CookbookMotion.screenUnderDim
    }
}
