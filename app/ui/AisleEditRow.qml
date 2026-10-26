import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// An aisle in the aisles editor: its color dot, its name edited in place, how
// many items it holds, then move up, move down and delete. Controlled: when
// the name's editing ends, renamed() gives the new name; the field then shows
// `name` again, whether the caller saved it or not. The dot emits
// colorClicked(); `dotButton` is there to anchor a color menu.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string name
    // The aisle's family; the dot is in its ink
    property colorFamily family
    // As given ("15 items")
    property string countText
    property bool canMoveUp: true
    property bool canMoveDown: true
    property bool canDelete: true
    // The delete button's accessible name, which can say why it's off
    property string deleteText: qsTr("Delete")

    readonly property Item dotButton: dot

    signal renamed(string name)
    signal colorClicked
    signal moveUpClicked
    signal moveDownClicked
    signal deleteClicked

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(CookbookMetrics.aisleRowHeight, implicitContentHeight + topPadding + bottomPadding)

    padding: 0

    contentItem: RowLayout {
        spacing: 0

        T.AbstractButton {
            id: dot

            implicitWidth: UiMetrics.sizeTouch
            implicitHeight: UiMetrics.sizeTouch
            text: qsTr("Color")
            Accessible.name: dot.text
            onClicked: control.colorClicked()

            contentItem: Item {
                Rectangle {
                    anchors.centerIn: parent
                    width: CookbookMetrics.aisleRowDot
                    height: width
                    radius: width / 2
                    color: control.family.ink
                }
            }

            background: Item {
                PressOverlay {
                    radius: width / 2
                    pressed: dot.down
                }

                FocusRing {
                    visible: dot.visualFocus
                    targetRadius: width / 2
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: UiMetrics.space1
            spacing: 0

            T.TextField {
                id: nameInput

                Layout.fillWidth: true
                implicitWidth: contentWidth + leftPadding + rightPadding
                implicitHeight: contentHeight + topPadding + bottomPadding
                padding: 0
                font: UiTypography.labelLBold
                color: control.theme.ink
                selectionColor: control.theme.accentSoft
                selectedTextColor: control.theme.ink
                Accessible.name: qsTr("Aisle name")

                // Shows `name` again once editing ends
                Binding on text {
                    when: !nameInput.activeFocus
                    value: control.name
                }

                onEditingFinished: {
                    if (nameInput.text !== control.name)
                        control.renamed(nameInput.text)
                }
                onAccepted: nameInput.focus = false

                background: Rectangle {
                    y: parent.height
                    width: parent.width
                    height: UiMetrics.borderStrong
                    visible: nameInput.activeFocus
                    color: control.theme.accent
                }
            }

            Text {
                Layout.fillWidth: true
                text: control.countText
                font: UiTypography.caption
                color: control.theme.inkMuted
                elide: Text.ElideRight
            }
        }

        IconButton {
            size: IconButton.Small
            variant: IconButton.Ghost
            enabled: control.canMoveUp
            icon.source: CookbookIcons.source("up")
            text: qsTr("Move up")
            onClicked: control.moveUpClicked()
        }

        IconButton {
            size: IconButton.Small
            variant: IconButton.Ghost
            enabled: control.canMoveDown
            icon.source: CookbookIcons.source("down")
            text: qsTr("Move down")
            onClicked: control.moveDownClicked()
        }

        IconButton {
            size: IconButton.Small
            variant: IconButton.Destructive
            enabled: control.canDelete
            icon.source: CookbookIcons.source("trash")
            text: control.deleteText
            onClicked: control.deleteClicked()
        }
    }
}
