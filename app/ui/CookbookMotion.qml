pragma Singleton

import QtQuick

// The app's own motion, used through UiMotion.move() and UiMotion.fade() like
// the library's
QtObject {
    id: root

    // A screen pushed over another slides in from the right; popped, it slides
    // back out, faster
    readonly property int screenPush: 280
    readonly property int screenPop: 220
    // Meanwhile the screen below shifts left by this share of its width, and
    // dims under the scrim color at this opacity
    readonly property real screenUnderShift: 0.2
    readonly property real screenUnderDim: 0.35
}
