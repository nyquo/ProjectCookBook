import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: window

    property int tapCount: 0

    // Phone-like size for desktop previews; ignored on Android (always fullscreen).
    width: 400
    height: 760
    visible: true
    title: AppInfo.name

    Material.theme: Material.System
    Material.primary: Material.DeepOrange
    Material.accent: Material.DeepOrange

    header: ToolBar {
        Label {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 16
            text: window.title
            font.pixelSize: 20
            font.weight: Font.Medium
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 420)
        spacing: 8

        Label {
            Layout.fillWidth: true
            text: qsTr("Hello from C++ and QML")
            font.pixelSize: 24
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Label {
            Layout.fillWidth: true
            text: `${AppInfo.platform} · ${AppInfo.cpuArchitecture}`
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Label {
            Layout.fillWidth: true
            text: qsTr("v%1 · Qt %2").arg(AppInfo.version).arg(AppInfo.qtVersion)
            opacity: 0.7
            horizontalAlignment: Text.AlignHCenter
        }

        Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 24
            highlighted: true
            text: window.tapCount === 0 ? qsTr("Tap me")
                                        : qsTr("Tapped %n time(s)", "", window.tapCount)
            onClicked: window.tapCount++
        }
    }
}
