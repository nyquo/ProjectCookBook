import QtQuick
import QtQuick.Templates as T
import Plating

// A big unfilled field for a title: its label above, an underline below that
// turns accent while focused. Medium is smaller and shows no label; the label
// stays its accessible name.
T.TextField {
    id: control

    enum Size {
        Default,
        Medium
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: TitleField.Default
    property string label

    implicitWidth: Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: contentHeight + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topPadding: labelText.visible ? labelText.height + UiMetrics.titleFieldLabelGap : 0
    bottomPadding: UiMetrics.titleFieldUnderlineGap + UiMetrics.borderStrong
    leftPadding: UiMetrics.titleFieldInset
    rightPadding: UiMetrics.titleFieldInset

    font: control.size === TitleField.Medium ? UiTypography.titleL : UiTypography.fieldTitle
    color: control.theme.ink
    placeholderTextColor: control.theme.inkMuted
    selectionColor: control.theme.accentSoft
    selectedTextColor: control.theme.ink

    Accessible.name: control.label

    Text {
        id: labelText

        x: UiMetrics.titleFieldInset
        visible: control.size === TitleField.Default && control.label !== ""
        width: control.width - 2 * UiMetrics.titleFieldInset
        text: control.label
        font: UiTypography.captionSemiBold
        color: control.theme.inkMuted
        elide: Text.ElideRight
    }

    Text {
        id: placeholder

        x: control.leftPadding
        y: control.topPadding
        width: control.width - control.leftPadding - control.rightPadding
        visible: control.length === 0 && control.preeditText === ""
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        elide: Text.ElideRight
    }

    background: Item {
        Rectangle {
            x: UiMetrics.titleFieldInset
            y: parent.height - height
            width: parent.width - 2 * UiMetrics.titleFieldInset
            height: UiMetrics.borderStrong
            color: control.activeFocus ? control.theme.accent : control.theme.line
        }
    }
}
