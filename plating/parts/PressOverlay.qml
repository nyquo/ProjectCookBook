import QtQuick
import Plating

// The pressed state: an overlay over its parent's fill, faded in and out. Set
// `radius` to the fill's.
Rectangle {
    id: overlay

    readonly property UiTheme theme: Plating.theme as UiTheme

    property bool pressed: false
    // The fill under it is ink, accent or danger rather than a light one
    property bool onStrongFill: false

    anchors.fill: parent
    color: overlay.onStrongFill ? overlay.theme.pressOverlayOnFill : overlay.theme.pressOverlay
    opacity: overlay.pressed ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: UiMotion.fade(UiMotion.press)
        }
    }
}
