import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// What a screen shows when it has nothing yet: an illustration, a title, a
// text and actions, centered
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property Item illustration
    property string title
    property string text
    // A large primary or a medium secondary Button
    property Item action
    // A text Button
    property Item secondaryAction

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    topPadding: UiMetrics.emptyPaddingV
    bottomPadding: UiMetrics.emptyPaddingV
    leftPadding: UiMetrics.emptyPaddingH
    rightPadding: UiMetrics.emptyPaddingH

    component Slot: Item {
        required property Item item

        visible: item !== null
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: item?.implicitWidth ?? 0
        implicitHeight: item?.implicitHeight ?? 0
        children: item ? [item] : []
    }

    contentItem: ColumnLayout {
        spacing: UiMetrics.emptyGap

        Slot {
            item: control.illustration
        }

        Text {
            Layout.fillWidth: true
            text: control.title
            font: UiTypography.emptyTitle
            lineHeightMode: Text.FixedHeight
            lineHeight: UiTypography.emptyTitleLineHeight
            color: control.theme.ink
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            Accessible.role: Accessible.Heading
        }

        Text {
            visible: control.text !== ""
            Layout.fillWidth: true
            text: control.text
            font: UiTypography.bodyL
            lineHeightMode: Text.FixedHeight
            lineHeight: UiTypography.bodyLLineHeight
            color: control.theme.inkMuted
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Slot {
            item: control.action
        }

        Slot {
            item: control.secondaryAction
        }
    }
}
