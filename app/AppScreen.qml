pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Plating
import CookbookUi

// A screen of the ScreenStack, on the bg color; its children fill it.
//
// A screen whose content can be pulled down at its top (RecipeScreen) can close
// that way: it calls dragPull() as the pull grows and releasePull() when the
// finger lifts. The screen follows, shrinking a little with rounded corners,
// while the ScreenStack shows the screen below. Released far enough, or
// flicked, it drops out of view and closes; otherwise it springs back. With
// reduced motion nothing moves: it cross-fades out, as Back does.
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

    // How far the screen is pulled down to close it, in px, as shown
    property real pull: 0
    // From 0 at rest to 1 once the pull would close it
    readonly property real pullProgress: Math.min(1, screen.pull / CookbookMetrics.screenPullDistance)
    // What moves on screen: nothing with reduced motion
    readonly property real shownPull: UiMotion.reduced ? 0 : screen.pull
    readonly property real shownPullProgress: UiMotion.reduced ? 0 : screen.pullProgress
    // The current drag's pulls, [{ time, pull }], to tell a flick
    property var pullSamples: []

    default property alias content: body.data

    // A message at the bottom of the window, with an optional action ("Undo")
    // that runs `action`
    function notify(message: string, actionText: string, action: var) {
        (screen.Window.window as Main)?.notify(message, actionText, action)
    }

    function dragPull(distance: real) {
        if (dropOut.running || screen.StackView.status !== StackView.Active)
            return
        settle.stop()
        screen.pullSamples = screen.pullSamples.concat([{ time: Date.now(), pull: distance }])
        screen.pull = distance
    }

    function releasePull() {
        if (dropOut.running)
            return
        // How much the pull grew in the drag's last moments
        const since = Date.now() - CookbookMotion.screenPullFlickTime
        let earlier = 0
        for (const sample of screen.pullSamples) {
            if (sample.time > since)
                break
            earlier = sample.pull
        }
        screen.pullSamples = []
        const flicked = screen.pull - earlier >= CookbookMetrics.screenPullFlickDistance
        if (screen.pull > 0 && (flicked || screen.pull >= CookbookMetrics.screenPullDistance))
            screen.closePulled()
        else
            settle.restart()
    }

    function closePulled() {
        if (!UiMotion.reduced) {
            dropOut.restart()
            return
        }
        screen.pull = 0
        screen.StackView.view.pop()
    }

    // Follows the finger from the top center: the screen's top stays under it
    transform: [
        Scale {
            id: pullScale

            origin.x: screen.width / 2
            xScale: 1 - (1 - CookbookMotion.screenPullScale) * screen.shownPullProgress
            yScale: pullScale.xScale
        },
        Translate {
            y: screen.shownPull
        }
    ]

    // Rounded corners while pulled, over the screen below
    layer.enabled: screen.shownPull > 0
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: pullMask
        // A soft threshold keeps the rounded corners antialiased
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }

    // Released as soon as another screen is pushed over this one
    KeepScreenOn {
        active: screen.keepScreenOn && (screen.StackView.status === StackView.Active
                                        || screen.StackView.status === StackView.Activating)
    }

    // Back to rest, when the pull wasn't enough
    NumberAnimation {
        id: settle

        target: screen
        property: "pull"
        to: 0
        duration: UiMotion.move(CookbookMotion.screenPop)
        easing.type: Easing.Bezier
        easing.bezierCurve: UiMotion.decelerate
    }

    // Out of view, then closed: the screen below came back meanwhile
    ParallelAnimation {
        id: dropOut

        NumberAnimation {
            target: screen
            property: "pull"
            to: screen.height
            duration: UiMotion.move(CookbookMotion.screenPop)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        NumberAnimation {
            target: screen
            property: "opacity"
            to: 0
            duration: UiMotion.fade(CookbookMotion.screenPop)
        }

        onFinished: screen.StackView.view.popCurrentItem(StackView.Immediate)
    }

    Rectangle {
        id: pullMask

        anchors.fill: parent
        visible: false
        layer.enabled: screen.shownPull > 0
        radius: UiMetrics.radiusSheet * screen.shownPullProgress
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
