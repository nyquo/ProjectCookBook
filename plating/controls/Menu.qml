pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Plating

// A menu of MenuItems, with an optional title. openUnder() opens it under an
// item; tapping outside closes it. Destructive items go last, after a
// MenuSeparator.
T.Menu {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // Opens under `anchor`, aligned to its left edge, or to its right edge when
    // it sits in the right half of the window
    function openUnder(anchor: Item) {
        const left = anchor.mapToItem(null, 0, 0).x
        const window = anchor.Window.window
        const rightHalf = window !== null && left + anchor.width / 2 > window.width / 2
        control.popup(anchor, rightHalf ? anchor.width - control.implicitWidth : 0,
                      anchor.height + UiMetrics.menuGap)
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    margins: UiMetrics.menuMargin
    padding: UiMetrics.menuPadding
    transformOrigin: T.Popup.Top

    delegate: MenuItem {}

    enter: Transition {
        NumberAnimation {
            property: "scale"
            from: UiMotion.reduced ? 1 : UiMotion.menuOpenScale
            to: 1
            duration: UiMotion.move(UiMotion.menuOpen)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
        NumberAnimation {
            property: "opacity"
            from: 0
            to: 1
            duration: UiMotion.fade(UiMotion.menuOpen)
        }
    }

    exit: Transition {
        NumberAnimation {
            property: "opacity"
            from: 1
            to: 0
            duration: UiMotion.fade(UiMotion.menuClose)
        }
    }

    contentItem: ListView {
        implicitHeight: contentHeight
        model: control.contentModel
        interactive: Window.window
                     ? contentHeight + control.topPadding + control.bottomPadding > control.height
                     : false
        clip: true
        currentIndex: control.currentIndex

        header: Text {
            width: ListView.view?.width ?? 0
            height: control.title !== "" ? implicitHeight : 0
            visible: control.title !== ""
            topPadding: UiMetrics.menuTitlePaddingTop
            leftPadding: UiMetrics.menuTitlePaddingH
            rightPadding: UiMetrics.menuTitlePaddingH
            bottomPadding: UiMetrics.menuTitlePaddingBottom
            text: control.title
            font: UiTypography.captionBold
            color: control.theme.inkMuted
            elide: Text.ElideRight
        }
    }

    background: MenuPanel {}
}
