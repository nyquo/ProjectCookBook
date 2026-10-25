import QtQuick
import QtQuick.Layouts
import Plating

// A showcase page: a pushed header and specimens, scrolling together
Page {
    id: page

    property string subtitle
    default property alias content: column.data
    // Everything the page shows, at full height, for --capture
    readonly property Item captureItem: canvas

    // For --capture: [{ name, show(), hide() }], states worth a window capture
    // (an open sheet, a menu)
    property var scenes: []

    // Scrolls so `item` is in view, e.g. a menu's anchor before it opens
    function reveal(item: Item) {
        const y = item.mapToItem(canvas, 0, 0).y
        flick.contentY = Math.max(0, Math.min(y - flick.height / 3, flick.contentHeight - flick.height))
    }

    // The four color families, for sample data
    readonly property colorFamily mint: ({ fill: page.theme.tagMint, ink: page.theme.tagMintInk })
    readonly property colorFamily butter: ({ fill: page.theme.tagButter, ink: page.theme.tagButterInk })
    readonly property colorFamily sky: ({ fill: page.theme.tagSky, ink: page.theme.tagSkyInk })
    readonly property colorFamily peach: ({ fill: page.theme.tagPeach, ink: page.theme.tagPeachInk })

    Flickable {
        id: flick

        anchors.fill: parent
        contentHeight: canvas.height
        boundsBehavior: Flickable.StopAtBounds

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
                    variant: ScreenHeader.Pushed
                    title: page.title
                    subtitle: page.subtitle
                    onBackClicked: page.StackView.view.pop()
                }

                ColumnLayout {
                    id: column

                    Layout.fillWidth: true
                    Layout.topMargin: UiMetrics.space4
                    Layout.leftMargin: UiMetrics.space4
                    Layout.rightMargin: UiMetrics.space4
                    Layout.bottomMargin: UiMetrics.space8 + page.SafeArea.margins.bottom
                    spacing: UiMetrics.space8
                }
            }
        }
    }
}
