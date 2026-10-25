pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

// The top of a recipe: its photo with back, favorite, edit and more buttons,
// then a sheet overlapping it with the tags, the name and the description.
// Without a photo, the first tag's color family and the name's initial. At the
// top of the window, its buttons clear the status bar (SafeArea).
Item {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property url photo
    // Shown without a photo
    property string initial
    // The first tag's family, behind the initial
    property colorFamily family
    // [{ name, family }]
    property var tags: []
    property string title
    property string description
    property bool favorite: false

    signal backClicked
    signal favoriteClicked
    signal editClicked
    signal moreClicked

    implicitWidth: sheet.implicitWidth
    implicitHeight: CookbookMetrics.recipeHeaderPhotoHeight - CookbookMetrics.recipeHeaderOverlap
                    + sheet.implicitHeight

    Rectangle {
        id: photoArea

        width: parent.width
        height: CookbookMetrics.recipeHeaderPhotoHeight
        color: control.family.fill

        // Centered in the part the sheet doesn't cover
        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: -CookbookMetrics.recipeHeaderOverlap / 2
            visible: image.status !== Image.Ready
            text: control.initial
            font: CookbookTypography.headerInitial
            color: control.family.ink
        }

        Image {
            id: image

            anchors.fill: parent
            source: control.photo
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: image.status === Image.Ready
        }
    }

    IconButton {
        x: CookbookMetrics.recipeHeaderButtonSide + control.SafeArea.margins.left
        y: CookbookMetrics.recipeHeaderButtonTop + control.SafeArea.margins.top
        size: IconButton.Large
        icon.name: "back"
        text: qsTr("Back")
        onClicked: control.backClicked()
    }

    Row {
        x: control.width - width - CookbookMetrics.recipeHeaderButtonSide - control.SafeArea.margins.right
        y: CookbookMetrics.recipeHeaderButtonTop + control.SafeArea.margins.top
        spacing: CookbookMetrics.recipeHeaderButtonGap

        IconButton {
            size: IconButton.Large
            variant: IconButton.Tint
            icon.name: "heart"
            text: qsTr("Favorite")
            checked: control.favorite
            Accessible.checkable: true
            Accessible.checked: control.favorite
            onClicked: control.favoriteClicked()
        }

        IconButton {
            size: IconButton.Large
            icon.name: "edit"
            text: qsTr("Edit")
            onClicked: control.editClicked()
        }

        IconButton {
            size: IconButton.Large
            icon.name: "more"
            text: qsTr("More")
            onClicked: control.moreClicked()
        }
    }

    Rectangle {
        id: sheet

        y: CookbookMetrics.recipeHeaderPhotoHeight - CookbookMetrics.recipeHeaderOverlap
        width: parent.width
        height: control.height - y
        implicitWidth: content.implicitWidth + 2 * CookbookMetrics.recipeHeaderPaddingH
        implicitHeight: content.implicitHeight + 2 * CookbookMetrics.recipeHeaderPaddingV
        topLeftRadius: UiMetrics.radiusSheet
        topRightRadius: UiMetrics.radiusSheet
        color: control.theme.bg

        ColumnLayout {
            id: content

            x: CookbookMetrics.recipeHeaderPaddingH + control.SafeArea.margins.left
            y: CookbookMetrics.recipeHeaderPaddingV
            width: parent.width - 2 * CookbookMetrics.recipeHeaderPaddingH
                   - control.SafeArea.margins.left - control.SafeArea.margins.right
            spacing: CookbookMetrics.recipeHeaderGap

            Flow {
                visible: control.tags.length > 0
                Layout.fillWidth: true
                spacing: CookbookMetrics.recipeHeaderTagGap

                Repeater {
                    model: control.tags

                    delegate: TagPill {
                        required property var modelData

                        size: TagPill.Large
                        text: modelData.name
                        family: modelData.family
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: control.title
                font: UiTypography.titleXL
                lineHeightMode: Text.FixedHeight
                lineHeight: UiTypography.titleXLLineHeight
                color: control.theme.ink
                wrapMode: Text.Wrap
                Accessible.role: Accessible.Heading
            }

            Text {
                visible: control.description !== ""
                Layout.fillWidth: true
                text: control.description
                font: UiTypography.bodyL
                lineHeightMode: Text.FixedHeight
                lineHeight: UiTypography.bodyLLineHeight
                color: control.theme.inkMuted
                wrapMode: Text.Wrap
            }
        }
    }
}
