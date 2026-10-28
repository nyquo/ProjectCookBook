import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// A tab's root screen: its title and the settings button, then its content.
// For now the content is empty.
Item {
    id: page

    property string title

    signal settingsClicked

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScreenHeader {
            Layout.fillWidth: true
            title: page.title
            trailing: IconButton {
                size: IconButton.Large
                icon.source: CookbookIcons.source("settings")
                text: qsTr("Settings")
                onClicked: page.settingsClicked()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
