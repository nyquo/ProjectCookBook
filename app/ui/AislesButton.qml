pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Templates as T
import Plating

// A pill that opens the aisles: the first aisles' colors as overlapping dots,
// then its text ("Aisles · 4"), on surface
T.Button {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // The aisles, in order: rows with `ink` and `darkInk` roles, like
    // AisleListModel's. The first three give the dots.
    property var model

    readonly property real dotStep: CookbookMetrics.aislesButtonDot - CookbookMetrics.aislesButtonDotOverlap

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0
    leftPadding: CookbookMetrics.aislesButtonPadding
    rightPadding: CookbookMetrics.aislesButtonPadding
    spacing: UiMetrics.space2
    font: UiTypography.labelBold

    contentItem: Row {
        spacing: control.spacing

        Item {
            readonly property int count: Math.min(dotRepeater.count, 3)

            anchors.verticalCenter: parent.verticalCenter
            width: count > 0 ? CookbookMetrics.aislesButtonDot + (count - 1) * control.dotStep : 0
            height: CookbookMetrics.aislesButtonDot
            visible: count > 0

            Repeater {
                id: dotRepeater

                model: control.model

                // Ringed in surface so each dot's edge shows over the previous one
                delegate: Rectangle {
                    id: dot

                    required property int index
                    required property color ink
                    required property color darkInk

                    x: dot.index * control.dotStep - CookbookMetrics.aislesButtonDotRing
                    y: -CookbookMetrics.aislesButtonDotRing
                    width: CookbookMetrics.aislesButtonDot + 2 * CookbookMetrics.aislesButtonDotRing
                    height: width
                    radius: width / 2
                    visible: dot.index < 3
                    color: control.theme.surface

                    Rectangle {
                        anchors.centerIn: parent
                        width: CookbookMetrics.aislesButtonDot
                        height: width
                        radius: width / 2
                        color: control.theme.dark ? dot.darkInk : dot.ink
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.text
            font: control.font
            color: control.theme.ink
        }
    }

    background: Rectangle {
        implicitHeight: UiMetrics.sizeTouch
        radius: height / 2
        color: control.theme.surface

        PressOverlay {
            radius: parent.radius
            pressed: control.down
        }

        FocusRing {
            visible: control.visualFocus
            targetRadius: parent.radius
        }
    }
}
