pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A sheet rising from the bottom over a scrim: a grip, a header (title,
// subtitle, an optional action on the right), the content, an optional footer.
// It fits its content, or is tall: its top stays sheetTopGap from the top of the
// window and the content (e.g. a Flickable with Layout.fillHeight) scrolls.
// Tapping the scrim or swiping it down dismisses it, unless it isn't
// dismissible.
T.Drawer {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string title
    property string subtitle
    // On the right of the title: a small secondary "Done", a text "Cancel"…
    property Item headerAction
    // A full-width large Button, or a row of buttons
    property Item footer
    property bool tall: false
    property bool dismissible: true
    // Laid out in a column: use Layout.fillWidth, Layout.fillHeight
    default property alias content: body.data

    readonly property real maxHeight: (control.parent?.height ?? 0) - UiMetrics.sheetTopGap

    parent: T.Overlay.overlay
    edge: Qt.BottomEdge
    modal: true
    interactive: control.dismissible
    // Opens from code only, never by a swipe from the bottom edge
    dragMargin: 0
    closePolicy: control.dismissible ? T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutside
                                     : T.Popup.NoAutoClose

    width: control.parent?.width ?? 0
    height: control.tall ? control.maxHeight
                         : Math.min(implicitContentHeight + topPadding + bottomPadding, control.maxHeight)

    topPadding: UiMetrics.sheetPaddingTop
    bottomPadding: (control.footer ? UiMetrics.sheetPaddingBottomCta : UiMetrics.sheetPaddingBottom)
                   + control.SafeArea.margins.bottom
    leftPadding: UiMetrics.sheetPaddingH + control.SafeArea.margins.left
    rightPadding: UiMetrics.sheetPaddingH + control.SafeArea.margins.right

    enter: Transition {
        NumberAnimation {
            duration: UiMotion.move(UiMotion.sheetRise)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
    }

    exit: Transition {
        NumberAnimation {
            duration: UiMotion.move(UiMotion.sheetDismiss)
            easing.type: Easing.Bezier
            easing.bezierCurve: UiMotion.decelerate
        }
    }

    onFooterChanged: {
        if (control.footer)
            control.footer.width = Qt.binding(() => footerSlot.width)
    }

    contentItem: ColumnLayout {
        spacing: UiMetrics.sheetGap

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: UiMetrics.sheetGripWidth
            implicitHeight: UiMetrics.sheetGripHeight
            radius: UiMetrics.sheetGripRadius
            color: control.theme.line
        }

        RowLayout {
            visible: control.title !== "" || control.headerAction !== null
            Layout.fillWidth: true
            spacing: UiMetrics.space3

            ColumnLayout {
                Layout.fillWidth: true
                spacing: UiMetrics.sheetSubtitleGap

                Text {
                    Layout.fillWidth: true
                    text: control.title
                    font: UiTypography.sheetTitle
                    lineHeightMode: Text.FixedHeight
                    lineHeight: UiTypography.sheetTitleLineHeight
                    color: control.theme.ink
                    wrapMode: Text.Wrap
                    Accessible.role: Accessible.Heading
                }

                Text {
                    visible: control.subtitle !== ""
                    Layout.fillWidth: true
                    text: control.subtitle
                    font: UiTypography.bodyM
                    lineHeightMode: Text.FixedHeight
                    lineHeight: UiTypography.bodyMLineHeight
                    color: control.theme.inkMuted
                    wrapMode: Text.Wrap
                }
            }

            Item {
                visible: control.headerAction !== null
                Layout.alignment: Qt.AlignTop
                implicitWidth: control.headerAction?.implicitWidth ?? 0
                implicitHeight: control.headerAction?.implicitHeight ?? 0
                children: control.headerAction ? [control.headerAction] : []
            }
        }

        ColumnLayout {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: control.tall
            spacing: UiMetrics.sheetGap
        }

        Item {
            id: footerSlot

            visible: control.footer !== null
            Layout.fillWidth: true
            implicitHeight: control.footer?.implicitHeight ?? 0
            children: control.footer ? [control.footer] : []
        }
    }

    background: Rectangle {
        topLeftRadius: UiMetrics.radiusSheet
        topRightRadius: UiMetrics.radiusSheet
        color: control.theme.bg
    }

    T.Overlay.modal: Rectangle {
        color: control.theme.scrim
    }
}
