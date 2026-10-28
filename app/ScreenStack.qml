import QtQuick
import Plating
import CookbookUi

// The app's screens (AppScreens), each pushed over the previous one. A pushed
// screen slides in from the right while the one below shifts left and dims;
// popping reverses it. With reduced motion, the screens stay in place and
// cross-fade. Back pops: Android's back button and gesture, Escape on
// desktop. On the first screen it's left unhandled, so Android does its
// default. While the top screen is pulled down to close it (AppScreen), the
// one below shows, coming back from its shifted, dimmed place as the pull
// grows.
StackView {
    id: stack

    // Pops; false on the first screen
    function goBack(): bool {
        if (stack.depth <= 1)
            return false
        stack.pop()
        return true
    }

    // 1 when screens enter from the right, -1 in right-to-left layouts
    readonly property real direction: stack.mirrored ? -1 : 1
    readonly property real pullProgress: (stack.currentItem as AppScreen)?.shownPullProgress ?? 0

    // StackView hides the screens under the top one; a pull shows the next one
    onPullProgressChanged: {
        const below = stack.depth > 1 ? stack.get(stack.depth - 2) as AppScreen : null
        if (!below || below === stack.currentItem)
            return
        below.visible = stack.pullProgress > 0
        below.x = -stack.direction * CookbookMotion.screenUnderShift * stack.width * (1 - stack.pullProgress)
        below.dim = 1 - stack.pullProgress
    }

    Keys.onBackPressed: event => event.accepted = stack.goBack()
    Keys.onEscapePressed: event => event.accepted = stack.goBack()

    pushEnter: Transition {
        NumberAnimation {
            property: "x"
            from: UiMotion.reduced ? 0 : stack.direction * stack.width
            to: 0
            duration: UiMotion.move(CookbookMotion.screenPush)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        NumberAnimation {
            property: "opacity"
            from: UiMotion.reduced ? 0 : 1
            to: 1
            duration: UiMotion.fade(CookbookMotion.screenPush)
        }
    }
    pushExit: Transition {
        NumberAnimation {
            property: "x"
            from: 0
            to: UiMotion.reduced ? 0 : -stack.direction * CookbookMotion.screenUnderShift * stack.width
            duration: UiMotion.move(CookbookMotion.screenPush)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        NumberAnimation {
            property: "dim"
            from: 0
            to: 1
            duration: UiMotion.fade(CookbookMotion.screenPush)
        }
    }
    popEnter: Transition {
        NumberAnimation {
            property: "x"
            from: UiMotion.reduced ? 0 : -stack.direction * CookbookMotion.screenUnderShift * stack.width
            to: 0
            duration: UiMotion.move(CookbookMotion.screenPop)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        NumberAnimation {
            property: "dim"
            from: 1
            to: 0
            duration: UiMotion.fade(CookbookMotion.screenPop)
        }
    }
    popExit: Transition {
        NumberAnimation {
            property: "x"
            from: 0
            to: UiMotion.reduced ? 0 : stack.direction * stack.width
            duration: UiMotion.move(CookbookMotion.screenPop)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        NumberAnimation {
            property: "opacity"
            from: 1
            to: UiMotion.reduced ? 0 : 1
            duration: UiMotion.fade(CookbookMotion.screenPop)
        }
    }
}
