import QtQuick
import QtQuick.Layouts
import Plating

// Loaded instead of Main when the database can't be opened
ApplicationWindow {
    id: window

    required property string details

    width: 400
    height: 760
    visible: true
    title: AppInfo.name

    Plating.theme: DefaultDarkTheme

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: 20
            text: qsTr("Can't open your data")
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            text: qsTr("%1 can't start. If you just installed an older version, install the latest one again.").arg(window.title)
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            textFormat: Text.PlainText
            opacity: 0.7
            text: window.details
        }

        Item {
            Layout.fillHeight: true
        }

        Button {
            Layout.alignment: Qt.AlignRight
            text: qsTr("Close")
            onClicked: Qt.quit()
        }
    }
}
