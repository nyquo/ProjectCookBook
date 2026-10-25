import QtQuick
import QtQuick.Layouts
import Plating

// A captioned block of a showcase page: one component's variants or states.
// Its children flow and wrap.
ColumnLayout {
    id: specimen

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string title
    property string note
    default property alias content: flow.data
    // Lays children out on a surface card, to show inset variants
    property bool onSurface: false
    // Spans the screen width, past the page margins (full-width components)
    property bool fullBleed: false

    Layout.fillWidth: true
    spacing: UiMetrics.space2

    Text {
        Layout.fillWidth: true
        text: specimen.title
        font: UiTypography.captionBold
        color: specimen.theme.inkMuted
        wrapMode: Text.Wrap
    }

    Text {
        visible: specimen.note !== ""
        Layout.fillWidth: true
        text: specimen.note
        font: UiTypography.caption
        color: specimen.theme.inkMuted
        wrapMode: Text.Wrap
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: specimen.fullBleed ? -UiMetrics.space4 : 0
        Layout.rightMargin: specimen.fullBleed ? -UiMetrics.space4 : 0
        implicitHeight: flow.implicitHeight + 2 * card.padding
        color: specimen.onSurface ? specimen.theme.surface : "transparent"
        radius: UiMetrics.radiusLg

        Item {
            id: card

            readonly property real padding: specimen.onSurface ? UiMetrics.space4 : 0

            anchors.fill: parent
            anchors.margins: card.padding

            Flow {
                id: flow

                width: parent.width
                spacing: UiMetrics.space3
            }
        }
    }
}
