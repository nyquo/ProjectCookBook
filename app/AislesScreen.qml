pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

// Throwaway screen exercising the aisle and tag color models end to end
ColumnLayout {
    id: screen

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string lastDeletedId
    // The tag color that Add and Recolor copy: the first one until another is
    // tapped
    property ColorChoice chosenColor

    // Shows the error, if any; returns true on success
    function show(error) {
        errorLabel.text = errorText(error)
        return error === AisleListModel.Error.NoError
    }

    function errorText(error) {
        switch (error) {
        case AisleListModel.Error.EmptyName:
            return qsTr("Enter a name.")
        case AisleListModel.Error.DuplicateName:
            return qsTr("An aisle with this name already exists.")
        case AisleListModel.Error.StorageFailed:
            return qsTr("Couldn't save the change.")
        default:
            return ""
        }
    }

    // A tag pill, in the current theme's variant of its colors
    component ColorChoice: Rectangle {
        id: pill

        readonly property UiTheme theme: Plating.theme as UiTheme

        required property string name
        required property color fill
        required property color ink
        required property color darkFill
        required property color darkInk
        property bool chosen: false

        signal tapped

        implicitWidth: pillText.implicitWidth + 2 * UiMetrics.space2
        implicitHeight: pillText.implicitHeight + 2 * UiMetrics.space1
        radius: UiMetrics.radiusPill
        color: pill.theme.dark ? pill.darkFill : pill.fill
        border.width: pill.chosen ? UiMetrics.focusRingWidth : 0
        border.color: pill.theme.ink

        Text {
            id: pillText

            anchors.centerIn: parent
            text: pill.name
            color: pill.theme.dark ? pill.darkInk : pill.ink
            font: UiTypography.tag
        }

        TapHandler {
            onTapped: pill.tapped()
        }
    }

    AisleListModel {
        id: aisles
    }

    TagColorListModel {
        id: tagColors
    }

    RowLayout {
        Layout.fillWidth: true

        TextField {
            id: nameField
            Layout.fillWidth: true
            placeholderText: qsTr("Aisle name")
        }

        Button {
            text: qsTr("Add")
            enabled: screen.chosenColor !== null
            onClicked: {
                const chosen = screen.chosenColor
                if (screen.show(aisles.create(nameField.text, chosen.fill, chosen.ink,
                                              chosen.darkFill, chosen.darkInk)))
                    nameField.clear()
            }
        }

        Button {
            text: qsTr("Undo")
            enabled: screen.lastDeletedId !== ""
            onClicked: {
                if (screen.show(aisles.restore(screen.lastDeletedId)))
                    screen.lastDeletedId = ""
            }
        }
    }

    Flow {
        Layout.fillWidth: true
        spacing: UiMetrics.space1

        Repeater {
            model: tagColors

            delegate: ColorChoice {
                id: swatch

                chosen: screen.chosenColor === swatch
                onTapped: screen.chosenColor = swatch
            }

            onItemAdded: (index, item) => {
                if (index === 0 && screen.chosenColor === null)
                    screen.chosenColor = item as ColorChoice
            }
        }
    }

    Label {
        id: errorLabel
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: aisles

        delegate: ColumnLayout {
            id: row

            required property int index
            required property string aisleId
            required property string name
            required property color fill
            required property color ink
            required property color darkFill
            required property color darkInk

            width: ListView.view.width

            RowLayout {
                spacing: UiMetrics.space2

                Label {
                    text: row.index
                }

                ColorChoice {
                    name: row.name
                    fill: row.fill
                    ink: row.ink
                    darkFill: row.darkFill
                    darkInk: row.darkInk
                }

                // The stored fill of the variant shown
                Label {
                    text: `${screen.theme.dark ? row.darkFill : row.fill}`
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 4

                Button {
                    // Renames to the text typed in the field above
                    text: qsTr("Rename")
                    onClicked: {
                        if (screen.show(aisles.rename(row.index, nameField.text)))
                            nameField.clear()
                    }
                }
                Button {
                    // Copies the chosen tag color
                    text: qsTr("Recolor")
                    enabled: screen.chosenColor !== null
                    onClicked: {
                        const chosen = screen.chosenColor
                        screen.show(aisles.setColors(row.index, chosen.fill, chosen.ink,
                                                     chosen.darkFill, chosen.darkInk))
                    }
                }
                Button {
                    text: qsTr("Up")
                    enabled: row.index > 0
                    onClicked: screen.show(aisles.move(row.index, row.index - 1))
                }
                Button {
                    text: qsTr("Down")
                    enabled: row.index < list.count - 1
                    onClicked: screen.show(aisles.move(row.index, row.index + 1))
                }
                Button {
                    text: qsTr("Delete")
                    onClicked: {
                        const id = row.aisleId
                        if (screen.show(aisles.remove(row.index)))
                            screen.lastDeletedId = id
                    }
                }
            }
        }
    }
}
