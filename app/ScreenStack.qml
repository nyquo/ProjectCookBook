import QtQuick
import Plating
import CookbookUi

// The app's screens (AppScreens), each pushed over the previous one. A pushed
// screen slides in from the right while the one below shifts left and dims;
// popping reverses it. Back pops: Android's back button and gesture, Escape on
// desktop. On the first screen it's left unhandled, so Android does its
// default.
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

    Keys.onBackPressed: event => event.accepted = stack.goBack()
    Keys.onEscapePressed: event => event.accepted = stack.goBack()

    pushEnter: Transition {
        NumberAnimation {
            property: "x"
            from: stack.direction * stack.width
            to: 0
            duration: UiMotion.move(CookbookMotion.screenPush)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        // With reduced motion, a fade instead of the slide
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
            to: -stack.direction * CookbookMotion.screenUnderShift * stack.width
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
            from: -stack.direction * CookbookMotion.screenUnderShift * stack.width
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
            to: stack.direction * stack.width
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
