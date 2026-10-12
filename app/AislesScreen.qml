pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Throwaway screen exercising the aisle model end to end.
ColumnLayout {
    id: screen

    property string lastDeletedId

    // Shows the error, if any; returns true on success.
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

    function colorName(color) {
        switch (color) {
        case AisleListModel.Color.Mint:
            return qsTr("Mint")
        case AisleListModel.Color.Butter:
            return qsTr("Butter")
        case AisleListModel.Color.Sky:
            return qsTr("Sky")
        case AisleListModel.Color.Peach:
            return qsTr("Peach")
        default:
            return ""
        }
    }

    AisleListModel {
        id: aisles
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
            onClicked: {
                if (screen.show(aisles.create(nameField.text, AisleListModel.Color.Mint)))
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
            required property int color

            width: ListView.view.width

            Label {
                text: `${row.index} · ${row.name} · ${screen.colorName(row.color)}`
            }

            Flow {
                Layout.fillWidth: true
                spacing: 4

                Button {
                    // Renames to the text typed in the field above.
                    text: qsTr("Rename")
                    onClicked: {
                        if (screen.show(aisles.rename(row.index, nameField.text)))
                            nameField.clear()
                    }
                }
                Button {
                    text: qsTr("Color")
                    onClicked: screen.show(aisles.setColor(row.index, (row.color + 1) % 4))
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
