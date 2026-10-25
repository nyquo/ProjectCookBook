import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A note, on the butter color family: a title over its text. Editable, the
// text is a borderless TextArea that emits textEdited().
T.Control {
    id: control

    enum Size {
        Default,
        Small
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: NoteCard.Default
    property string title
    property string text
    property bool editable: false
    property string placeholderText

    signal textEdited(string text)

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: CookbookMetrics.noteCardPadding

    contentItem: ColumnLayout {
        spacing: CookbookMetrics.noteCardGap

        Text {
            visible: control.title !== ""
            Layout.fillWidth: true
            text: control.title
            font: control.size === NoteCard.Small ? UiTypography.labelLExtraBold : UiTypography.titleS
            color: control.theme.tagButterInk
            wrapMode: Text.Wrap
            Accessible.role: Accessible.Heading
        }

        Text {
            visible: !control.editable
            Layout.fillWidth: true
            text: control.text
            font: UiTypography.bodyL
            lineHeightMode: Text.FixedHeight
            lineHeight: UiTypography.bodyLLineHeight
            color: control.theme.tagButterInk
            wrapMode: Text.Wrap
        }

        TextArea {
            id: area

            visible: control.editable
            Layout.fillWidth: true
            borderless: true
            text: control.text
            placeholderText: control.placeholderText
            color: control.theme.tagButterInk
            Accessible.name: control.title
            onTextChanged: {
                if (area.text !== control.text)
                    control.textEdited(area.text)
            }
        }
    }

    background: Rectangle {
        radius: UiMetrics.radiusMd
        color: control.theme.tagButter
        border.width: control.editable && area.activeFocus ? UiMetrics.borderStrong : 0
        border.color: control.theme.tagButterInk
    }
}
