import QtQuick
import QtQuick.Controls.Material

ApplicationWindow {
    id: window

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

    AislesScreen {
        anchors.fill: parent
        anchors.margins: 8
    }

    footer: Label {
        padding: 8
        opacity: 0.7
        elide: Text.ElideRight
        text: `${AppInfo.platform} · ${AppInfo.cpuArchitecture} · `
              + qsTr("v%1 · Qt %2").arg(AppInfo.version).arg(AppInfo.qtVersion)
    }
}
