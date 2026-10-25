import QtQuick
import QtQuick.Templates as T
import Plating

// Multi-line text that grows with its content. An optional label above it and
// a counter under it, on the right. Borderless, it has no fill and takes the
// text color it's given. Lines keep the font's own spacing, not body-l's 1.5:
// Qt's text editor has no line height.
T.TextArea {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // Sits on a surface: fills with bg instead
    property bool inset: false
    property bool borderless: false
    property string label
    // As given ("66 / 200")
    property string counterText

    implicitWidth: Math.max(contentWidth, placeholder.implicitWidth) + leftPadding + rightPadding
    implicitHeight: Math.max(contentHeight, placeholder.implicitHeight) + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topInset: labelText.visible ? labelText.height + UiMetrics.textFieldLabelGap : 0
    bottomInset: counter.visible ? counter.height + UiMetrics.textFieldLabelGap : 0
    topPadding: topInset + (control.borderless ? 0 : UiMetrics.textAreaPaddingV)
    bottomPadding: bottomInset + (control.borderless ? 0 : UiMetrics.textAreaPaddingV)
    leftPadding: control.borderless ? 0 : UiMetrics.textAreaPaddingH
    rightPadding: control.leftPadding

    font: UiTypography.bodyL
    color: control.theme.ink
    placeholderTextColor: control.borderless ? Qt.alpha(control.color, UiMetrics.opacitySecondary)
                                             : control.theme.inkMuted
    selectionColor: control.theme.accentSoft
    selectedTextColor: control.theme.ink
    wrapMode: TextEdit.Wrap

    Accessible.name: control.label !== "" ? control.label : control.placeholderText

    Text {
        id: labelText

        x: UiMetrics.textFieldLabelInset
        visible: control.label !== ""
        width: control.width - 2 * UiMetrics.textFieldLabelInset
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
        wrapMode: Text.Wrap
    }

    Text {
        id: counter

        x: control.width - width - UiMetrics.textFieldLabelInset
        y: control.height - height
        visible: control.counterText !== ""
        text: control.counterText
        font: UiTypography.overlineMedium
        color: control.theme.inkMuted
    }

    background: Rectangle {
        visible: !control.borderless
        radius: UiMetrics.radiusMd
        color: control.inset ? control.theme.bg : control.theme.surface
        border.width: control.activeFocus ? UiMetrics.borderStrong : 0
        border.color: control.theme.accent
    }
}
