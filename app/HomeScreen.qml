pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// The first screen: the three tabs over the bottom bar. Each tab keeps its
// state while another one is shown; the tab shown fades in while rising.
AppScreen {
    id: screen

    signal settingsClicked

    // A tab of the StackLayout
    component Tab: TabPage {
        id: tab

        property real rise: 0

        function enter() {
            appear.restart()
        }

        transform: Translate {
            y: tab.rise
        }

        onSettingsClicked: screen.settingsClicked()

        ParallelAnimation {
            id: appear

            NumberAnimation {
                target: tab
                property: "opacity"
                from: 0
                to: 1
                duration: UiMotion.fade(UiMotion.pageEnter)
            }
            NumberAnimation {
                target: tab
                property: "rise"
                from: UiMotion.reduced ? 0 : UiMetrics.pageEnterOffset
                to: 0
                duration: UiMotion.move(UiMotion.pageEnter)
                easing.type: Easing.Bezier
                easing.bezierCurve: UiMotion.decelerate
            }
        }
    }

    snackbarOffset: nav.height

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StackLayout {
            id: tabs

            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: nav.currentIndex

            onCurrentIndexChanged: (tabs.children[tabs.currentIndex] as Tab)?.enter()

            Tab {
                title: qsTr("Recipes")
            }
            Tab {
                title: qsTr("Planning")
            }
            Tab {
                title: qsTr("Shopping list")
            }
        }

        BottomNav {
            id: nav

            Layout.fillWidth: true

            BottomNavItem {
                text: qsTr("Recipes")
                icon.source: CookbookIcons.source("recipes")
            }
            BottomNavItem {
                text: qsTr("Planning")
                icon.source: CookbookIcons.source("planning")
            }
            BottomNavItem {
                text: qsTr("Shopping list")
                icon.source: CookbookIcons.source("shopping")
            }
        }
    }
}
