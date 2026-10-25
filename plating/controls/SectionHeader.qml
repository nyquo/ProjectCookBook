import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// The label above a card: "Produce · 3". Place it right above the card; it
// keeps the gap to it.
T.Control {
    id: control

    enum Size {
        Default,
        // Bigger text and an optional action on the right ("Clear")
        Large
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int size: SectionHeader.Default
    property string text
    // Shown after the text, as given
    property string count
    // A dot before the text, e.g. an aisle's color; none while transparent
    property color dotColor: "transparent"
    // Large: a small quiet button on the right
    property string actionText

    signal actionClicked

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    padding: 0
    leftPadding: UiMetrics.sectionHeaderInset
    rightPadding: UiMetrics.sectionHeaderInset
    bottomPadding: UiMetrics.sectionHeaderGap

    contentItem: RowLayout {
        spacing: UiMetrics.space2

        Rectangle {
            visible: control.dotColor.a > 0
            implicitWidth: UiMetrics.sectionHeaderDot
            implicitHeight: UiMetrics.sectionHeaderDot
            radius: width / 2
            color: control.dotColor
        }

        Text {
            Layout.fillWidth: true
            text: control.count !== "" ? `${control.text} · ${control.count}` : control.text
            font: control.size === SectionHeader.Large ? UiTypography.labelLExtraBold
                                                       : UiTypography.captionBold
            color: control.theme.inkMuted
            elide: Text.ElideRight
            Accessible.role: Accessible.Heading
        }

        Button {
            visible: control.size === SectionHeader.Large && control.actionText !== ""
            variant: Button.Quiet
            size: Button.Small
            text: control.actionText
            onClicked: control.actionClicked()
        }
    }
}
