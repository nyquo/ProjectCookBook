pragma Singleton

import QtQuick

// Every animation's duration and easing, and the reduced-motion switch they all
// go through. With `reduced`, an animation that moves, scales or resizes runs in
// 0 ms and fades take at most `reducedFade`: components check `reduced` and drop
// the movement. Numbers that change (counters, rescaled quantities) never
// animate.
QtObject {
    id: root

    // Set by the app (e.g. from a setting); off by default
    property bool reduced: false

    // The longest a fade may take with reduced motion
    readonly property int reducedFade: 120

    // "Decelerating": cubic-bezier(0.2, 0.8, 0.2, 1), for easing.bezierCurve
    // with Easing.Bezier
    readonly property list<real> decelerate: [0.2, 0.8, 0.2, 1, 1, 1]

    // Pressed overlay in and out
    readonly property int press: 100
    // Switch thumb: moves and grows
    readonly property int toggle: 160
    // Menu: opens (scaling from menuOpenScale and fading in) and closes
    readonly property int menuOpen: 160
    readonly property int menuClose: 120
    readonly property real menuOpenScale: 0.96
    // A page entering: fades in while rising
    readonly property int pageEnter: 180
    // A check mark popping in, from checkPopScale
    readonly property int checkPop: 180
    readonly property real checkPopScale: 0.8
    // Scrim fading in; a bottom sheet dismissing
    readonly property int scrimFade: 200
    readonly property int sheetDismiss: 200
    // A bottom sheet rising
    readonly property int sheetRise: 320
    // A snackbar rising and fading in; how long it stays; fading out
    readonly property int snackbarEnter: 220
    readonly property int snackbarStay: 4000
    readonly property int snackbarLeave: 160
    // Press and hold: the row shrinks to longPressScale over the hold, springs
    // back if released early
    readonly property int longPress: 480
    readonly property int longPressRelease: 160
    readonly property real longPressScale: 0.96
    // A checked shopping item leaving its group, then landing in the cart
    readonly property int listLeave: 340
    readonly property int listLand: 300

    // The duration of an animation that moves, scales or resizes
    function move(duration: int): int {
        return root.reduced ? 0 : duration
    }

    // The duration of a fade
    function fade(duration: int): int {
        return root.reduced ? Math.min(duration, root.reducedFade) : duration
    }
}
