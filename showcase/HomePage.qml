pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

// The list of pages, in two sections
Page {
    id: page

    required property list<PageEntry> pages
    readonly property Item captureItem: canvas

    signal opened(PageEntry entry)

    component Section: ColumnLayout {
        id: section

        required property string title
        required property bool app

        Layout.fillWidth: true
        spacing: 0

        SectionHeader {
            Layout.fillWidth: true
            text: section.title
        }

        ListGroup {
            Layout.fillWidth: true

            Repeater {
                model: page.pages.filter(entry => entry.app === section.app)

                delegate: ListRow {
                    required property PageEntry modelData

                    text: modelData.title
                    subtitle: modelData.summary
                    chevron: true
                    onClicked: page.opened(modelData)
                }
            }
        }
    }

    ScrollArea {
        id: flick

        anchors.fill: parent
        contentHeight: canvas.height

        Rectangle {
            id: canvas

            width: flick.width
            height: layout.implicitHeight
            color: page.theme.bg

            ColumnLayout {
                id: layout

                width: parent.width
                spacing: 0

                ScreenHeader {
                    Layout.fillWidth: true
                    variant: ScreenHeader.TopLevel
                    title: qsTr("Showcase")
                    subtitle: qsTr("Plating, the component library, and the app's own components")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: UiMetrics.space4
                    Layout.leftMargin: UiMetrics.space4
                    Layout.rightMargin: UiMetrics.space4
                    Layout.bottomMargin: UiMetrics.space8 + page.SafeArea.margins.bottom
                    spacing: UiMetrics.space6

                    Section {
                        title: qsTr("Library")
                        app: false
                    }

                    Section {
                        title: qsTr("App")
                        app: true
                    }
                }
            }
        }
    }
}
