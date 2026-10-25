pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// − and + around a value, given as text. It counts nothing itself: it emits
// decreaseClicked() and increaseClicked(), and the caller updates `text` and
// says when either end is reached. At the minimum, − looks disabled; removable,
// it becomes a trash that emits removeClicked() instead.
T.Control {
    id: control

    enum Size {
        // bg capsule, 44 buttons, the number over its unit
        Default,
        // 40 buttons, the value on one line
        Small,
        // No capsule, 56 buttons, a big number over its unit
        Large
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: Stepper.Default
    // The value, as shown ("6", or "6 servings" when Small)
    property string text
    // Under the value, Default and Large only ("servings")
    property string unit
    property bool canDecrease: true
    property bool canIncrease: true
    property bool removable: false
    // Shown instead of the value, e.g. an input
    property Item valueItem

    signal decreaseClicked
    signal increaseClicked
    signal removeClicked

    readonly property bool large: control.size === Stepper.Large
    readonly property bool small: control.size === Stepper.Small
    readonly property real buttonSize: control.small ? UiMetrics.stepperButtonS
                                                     : control.large ? UiMetrics.stepperButtonL
                                                                     : UiMetrics.stepperButton
    readonly property real iconSize: control.small ? UiMetrics.iconM
                                                   : control.large ? UiMetrics.sizeIcon : UiMetrics.iconL
    readonly property bool removes: control.removable && !control.canDecrease

    // A round − or + button. Inactive: no fill, a line ring, a muted icon
    component StepButton: T.Button {
        id: button

        property string glyph
        property bool inactive: false

        implicitWidth: control.buttonSize
        implicitHeight: control.buttonSize
        enabled: !button.inactive
        display: T.AbstractButton.IconOnly

        contentItem: Item {
            Icon {
                anchors.centerIn: parent
                width: control.iconSize
                height: control.iconSize
                name: button.glyph
                color: button.inactive ? control.theme.inkMuted : control.theme.accent
                strokeWidth: button.glyph === "trash" ? NaN : UiMetrics.iconStrokeEmphasis
            }
        }

        background: Rectangle {
            radius: width / 2
            color: button.inactive ? "transparent" : control.theme.accentSoft
            border.width: button.inactive ? UiMetrics.borderThin : 0
            border.color: control.theme.line

            PressOverlay {
                radius: parent.radius
                pressed: button.down
            }

            FocusRing {
                visible: button.visualFocus
                targetRadius: parent.radius
            }
        }
    }

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: control.large ? 0 : UiMetrics.stepperPadding
    spacing: control.large ? UiMetrics.stepperGapL : UiMetrics.stepperGap
    font: control.small ? UiTypography.labelExtraBold
                        : control.large ? UiTypography.stepperValueL : UiTypography.titleS

    contentItem: RowLayout {
        spacing: control.spacing

        StepButton {
            glyph: control.removes ? "trash" : "minus"
            inactive: !control.canDecrease && !control.removes
            text: control.removes ? qsTr("Remove") : qsTr("Decrease")
            onClicked: control.removes ? control.removeClicked() : control.decreaseClicked()
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: control.valueItem ? 0 : control.small ? UiMetrics.stepperValueMinWidthS
                                               : control.large ? 0 : UiMetrics.stepperValueMinWidth
            implicitWidth: control.valueItem ? control.valueItem.implicitWidth : value.implicitWidth
            implicitHeight: Math.max(control.buttonSize,
                                     control.valueItem ? control.valueItem.implicitHeight : value.implicitHeight)

            ColumnLayout {
                id: value

                anchors.centerIn: parent
                visible: control.valueItem === null
                spacing: control.large ? UiMetrics.stepperUnitGapL : 0

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: control.text
                    font: control.font
                    color: control.theme.ink
                }

                Text {
                    visible: !control.small && control.unit !== ""
                    Layout.alignment: Qt.AlignHCenter
                    text: control.unit
                    font: control.large ? UiTypography.labelS : UiTypography.micro
                    color: control.theme.inkMuted
                }
            }

            Item {
                anchors.centerIn: parent
                visible: control.valueItem !== null
                width: control.valueItem?.implicitWidth ?? 0
                height: control.valueItem?.implicitHeight ?? 0
                children: control.valueItem ? [control.valueItem] : []
            }
        }

        StepButton {
            glyph: "plus"
            inactive: !control.canIncrease
            text: qsTr("Increase")
            onClicked: control.increaseClicked()
        }
    }

    background: Rectangle {
        visible: !control.large
        radius: height / 2
        color: control.theme.bg
    }
}
