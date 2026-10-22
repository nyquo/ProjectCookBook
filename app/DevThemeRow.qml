import QtQuick
import QtQuick.Layouts
import Plating

// TEMPORARY, for trying the themes until the settings exist: remove this file,
// its entry in CMakeLists.txt and its uses in Main.qml then.
RowLayout {
    id: row

    // Qt.ColorScheme.Unknown follows the system
    readonly property int scheme: schemeBox.currentValue ?? Qt.ColorScheme.Unknown
    readonly property int accentChoice: accentBox.currentValue ?? UiTheme.Raspberry

    ComboBox {
        id: schemeBox

        Layout.fillWidth: true
        textRole: "text"
        valueRole: "value"
        model: [
            { text: qsTr("System"), value: Qt.ColorScheme.Unknown },
            { text: qsTr("Light"), value: Qt.ColorScheme.Light },
            { text: qsTr("Dark"), value: Qt.ColorScheme.Dark }
        ]
    }

    ComboBox {
        id: accentBox

        Layout.fillWidth: true
        textRole: "text"
        valueRole: "value"
        model: [
            { text: qsTr("Raspberry"), value: UiTheme.Raspberry },
            { text: qsTr("Spirulina"), value: UiTheme.Spirulina },
            { text: qsTr("Blueberry"), value: UiTheme.Blueberry },
            { text: qsTr("Saffron"), value: UiTheme.Saffron },
            { text: qsTr("Basil"), value: UiTheme.Basil }
        ]
    }
}
