import QtQuick
import QtQuick.Templates as T
import Plating

// An ingredient's quantity, as given ("1,2 kg"); "To taste" without one. It
// grows with its text.
T.Control {
    id: control

    enum Variant {
        Default,
        // In list rows: narrower, bigger text
        List,
        // In step cards and amount chips
        Small
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int variant: QuantityPill.Default
    property string quantity

    readonly property bool small: control.variant === QuantityPill.Small

    implicitWidth: Math.max(control.variant === QuantityPill.List ? CookbookMetrics.quantityPillListMinWidth
                            : control.small ? CookbookMetrics.quantityPillSmallMinWidth
                                            : CookbookMetrics.quantityPillMinWidth,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: control.small ? CookbookMetrics.quantityPillSmallHeight
                                  : CookbookMetrics.quantityPillHeight

    padding: 0
    leftPadding: control.small ? CookbookMetrics.quantityPillSmallPadding
                               : CookbookMetrics.quantityPillPadding
    rightPadding: control.leftPadding
    font: control.variant === QuantityPill.List ? UiTypography.labelExtraBold
          : control.small ? UiTypography.captionExtraBold : UiTypography.qty

    Accessible.role: Accessible.StaticText
    Accessible.name: label.text

    contentItem: Text {
        id: label

        text: control.quantity !== "" ? control.quantity : qsTr("To taste")
        font: control.font
        color: control.theme.accent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        radius: height / 2
        color: control.theme.accentSoft
    }
}
