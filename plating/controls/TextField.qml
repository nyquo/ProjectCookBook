import QtQuick
import QtQuick.Templates as T
import Plating

// A pill text field. Above the pill an optional label, below it an optional
// helper text; inside, an optional leading icon, a suffix after the value and a
// trailing submit or clear button.
T.TextField {
    id: control

    enum Size {
        Default,
        // h44, for dense forms
        Compact
    }

    enum Action {
        NoAction,
        // An accent + that emits accepted()
        Submit,
        // An × that clears the text, shown while there is some
        Clear
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: TextField.Default
    // Sits on a surface: fills with bg instead
    property bool inset: false
    property string label
    property string helperText
    // Invalid: a danger ring, and the helper text in danger
    property bool error: false
    // Shown right after the value ("min")
    property string suffix
    // A UiIcons name, before the text
    property string leadingIcon
    property int trailingAction: TextField.NoAction
    // A number: bigger value, decimal keyboard, comma or dot as the separator
    property bool numeric: false

    readonly property bool compact: control.size === TextField.Compact
    readonly property real pillHeight: control.compact ? UiMetrics.textFieldHeightCompact
                                                       : UiMetrics.textFieldHeight
    readonly property real sidePadding: control.compact ? UiMetrics.textFieldPaddingCompact
                                                        : UiMetrics.textFieldPadding
    readonly property bool showsAction: control.trailingAction === TextField.Submit
                                        || (control.trailingAction === TextField.Clear && control.length > 0)

    implicitWidth: Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: topInset + control.pillHeight + bottomInset

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topInset: labelText.visible ? labelText.height + UiMetrics.textFieldLabelGap : 0
    bottomInset: helper.visible ? helper.height + UiMetrics.textFieldLabelGap : 0
    topPadding: topInset
    bottomPadding: bottomInset
    leftPadding: control.sidePadding
                 + (control.leadingIcon !== "" ? UiMetrics.iconL + UiMetrics.textFieldIconGap : 0)
    rightPadding: (control.showsAction ? UiMetrics.textFieldActionPadding + UiMetrics.iconButtonSizeS
                                         + UiMetrics.textFieldIconGap
                                       : control.sidePadding)
                  + (control.suffix !== "" ? suffixText.implicitWidth + UiMetrics.textFieldSuffixGap : 0)

    font: control.numeric ? UiTypography.titleS : UiTypography.bodyL
    color: control.theme.ink
    placeholderTextColor: control.theme.inkMuted
    selectionColor: control.theme.accentSoft
    selectedTextColor: control.theme.ink
    verticalAlignment: TextInput.AlignVCenter
    inputMethodHints: control.numeric ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
    validator: control.numeric ? numberValidator : null

    Accessible.name: control.label !== "" ? control.label : control.placeholderText

    RegularExpressionValidator {
        id: numberValidator

        regularExpression: /^[0-9]*([.,][0-9]*)?$/
    }

    Text {
        id: labelText

        x: UiMetrics.textFieldLabelInset
        visible: control.label !== ""
        width: control.width - 2 * UiMetrics.textFieldLabelInset
        text: control.label
        font: control.compact ? UiTypography.overline : UiTypography.captionSemiBold
        color: control.theme.inkMuted
        elide: Text.ElideRight
    }

    Text {
        id: placeholder

        x: control.leftPadding
        y: control.topPadding
        width: control.width - control.leftPadding - control.rightPadding
        height: control.pillHeight
        visible: control.length === 0 && control.preeditText === ""
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    Text {
        id: suffixText

        x: control.leftPadding + Math.min(control.contentWidth,
                                          control.width - control.leftPadding - control.rightPadding)
           + UiMetrics.textFieldSuffixGap
        y: control.topPadding
        height: control.pillHeight
        visible: control.suffix !== "" && control.length > 0
        text: control.suffix
        font: UiTypography.bodyS
        color: control.theme.inkMuted
        verticalAlignment: Text.AlignVCenter
    }

    Icon {
        x: control.sidePadding
        y: control.topPadding + (control.pillHeight - height) / 2
        width: UiMetrics.iconL
        height: UiMetrics.iconL
        visible: control.leadingIcon !== ""
        name: control.leadingIcon
        color: control.theme.inkMuted
    }

    IconButton {
        x: control.width - width - UiMetrics.textFieldActionPadding
        y: control.topPadding + (control.pillHeight - height) / 2
        visible: control.showsAction
        size: IconButton.Small
        variant: control.trailingAction === TextField.Submit ? IconButton.Accent : IconButton.Ghost
        icon.name: control.trailingAction === TextField.Submit ? "plus" : "close"
        text: control.trailingAction === TextField.Submit ? qsTr("Add") : qsTr("Clear")
        // Keeps the keyboard up
        focusPolicy: Qt.NoFocus
        onClicked: {
            if (control.trailingAction === TextField.Submit)
                control.accepted()
            else
                control.clear()
        }
    }

    Text {
        id: helper

        x: UiMetrics.textFieldLabelInset
        y: control.height - height
        visible: control.helperText !== ""
        width: control.width - 2 * UiMetrics.textFieldLabelInset
        text: control.helperText
        font: UiTypography.caption
        lineHeightMode: Text.FixedHeight
        lineHeight: UiTypography.captionLineHeight
        color: control.error ? control.theme.danger : control.theme.inkMuted
        wrapMode: Text.Wrap
    }

    background: Rectangle {
        radius: height / 2
        color: control.inset ? control.theme.bg : control.theme.surface
        border.width: control.error || control.activeFocus ? UiMetrics.borderStrong : 0
        border.color: control.error ? control.theme.danger : control.theme.accent
    }
}
