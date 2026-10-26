pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

// A card that adds an aisle: its name, one of `colors`, and an Add button,
// ringed in accent-soft. Controlled: Add and the keyboard's Enter emit
// addClicked(); the caller adds the aisle and clears `name`.
Card {
    id: control

    property alias name: nameField.text
    property alias placeholderText: nameField.placeholderText
    // [{ name, family }]
    property var colors: []
    property int colorIndex: 0

    signal addClicked

    padding: CookbookMetrics.aisleFormPadding
    ringColor: control.theme.accentSoft

    ColumnLayout {
        spacing: CookbookMetrics.aisleFormGap

        TextField {
            id: nameField

            Layout.fillWidth: true
            inset: true
            onAccepted: control.addClicked()
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: UiMetrics.space2

            Text {
                text: qsTr("Color")
                font: UiTypography.labelBold
                color: control.theme.ink
            }

            // The dots' targets already keep them apart
            Row {
                Repeater {
                    model: control.colors

                    delegate: ColorDot {
                        required property var modelData
                        required property int index

                        text: modelData.name
                        family: modelData.family
                        checked: index === control.colorIndex
                        onClicked: control.colorIndex = index
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                variant: Button.Primary
                size: Button.Small
                text: qsTr("Add")
                onClicked: control.addClicked()
            }
        }
    }
}
