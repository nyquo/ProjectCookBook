import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A recipe on the meal plan: thumbnail, name and a meta line, a remove button,
// then its servings stepper and "Cooked it"
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string title
    // As given ("Tuesday · 35 min")
    property string meta
    property url thumbnail
    property string initials
    property colorFamily family
    // The stepper's value, as given ("4 servings")
    property string servings
    property bool canDecrease: true
    property bool canIncrease: true

    signal removeClicked
    signal decreaseClicked
    signal increaseClicked
    signal cookedClicked

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: CookbookMetrics.plannedCardPadding

    contentItem: ColumnLayout {
        spacing: CookbookMetrics.plannedCardGap

        RowLayout {
            Layout.fillWidth: true
            spacing: CookbookMetrics.plannedCardGap

            Thumbnail {
                source: control.thumbnail
                initials: control.initials
                family: control.family
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: control.title
                    font: UiTypography.valueBold
                    color: control.theme.ink
                    elide: Text.ElideRight
                }

                Text {
                    visible: control.meta !== ""
                    Layout.fillWidth: true
                    text: control.meta
                    font: UiTypography.caption
                    color: control.theme.inkMuted
                    elide: Text.ElideRight
                }
            }

            IconButton {
                Layout.alignment: Qt.AlignTop
                size: IconButton.Small
                variant: IconButton.Ghost
                icon.name: "close"
                text: qsTr("Remove from the plan")
                onClicked: control.removeClicked()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: CookbookMetrics.plannedCardGap

            Stepper {
                size: Stepper.Small
                text: control.servings
                canDecrease: control.canDecrease
                canIncrease: control.canIncrease
                onDecreaseClicked: control.decreaseClicked()
                onIncreaseClicked: control.increaseClicked()
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                variant: Button.Secondary
                size: Button.Small
                icon.name: "check"
                text: qsTr("Cooked it")
                onClicked: control.cookedClicked()
            }
        }
    }

    background: Rectangle {
        radius: UiMetrics.radiusLg
        color: control.theme.surface
    }
}
