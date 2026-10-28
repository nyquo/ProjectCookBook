pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

// The top of a recipe: its photo with back, favorite, edit and more buttons,
// then a sheet overlapping it with the tags, the name and the description.
// Without a photo, the first tag's color family and the name's initial. At the
// top of the window, its buttons clear the status bar (SafeArea). Items given
// to it are further sections of the sheet, under the description.
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
    // False when the screen floats its own RecipeActions
    property bool showActions: true
    // Under the last section, e.g. to clear floating buttons
    property real sheetBottomPadding: CookbookMetrics.recipeHeaderPaddingV
    default property alias content: sections.data

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
            sourceSize: Qt.size(width, height)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: image.status === Image.Ready
        }
    }

    RecipeActions {
        width: parent.width
        visible: control.showActions
        favorite: control.favorite
        onBackClicked: control.backClicked()
        onFavoriteClicked: control.favoriteClicked()
        onEditClicked: control.editClicked()
        onMoreClicked: control.moreClicked()
    }

    Rectangle {
        id: sheet

        y: CookbookMetrics.recipeHeaderPhotoHeight - CookbookMetrics.recipeHeaderOverlap
        width: parent.width
        height: control.height - y
        implicitWidth: sections.implicitWidth + 2 * CookbookMetrics.recipeHeaderPaddingH
        implicitHeight: CookbookMetrics.recipeHeaderPaddingV + sections.implicitHeight + control.sheetBottomPadding
        topLeftRadius: UiMetrics.radiusSheet
        topRightRadius: UiMetrics.radiusSheet
        color: control.theme.bg

        ColumnLayout {
            id: sections

            x: CookbookMetrics.recipeHeaderPaddingH + control.SafeArea.margins.left
            y: CookbookMetrics.recipeHeaderPaddingV
            width: parent.width - 2 * CookbookMetrics.recipeHeaderPaddingH
                   - control.SafeArea.margins.left - control.SafeArea.margins.right
            spacing: CookbookMetrics.recipeSectionGap

            ColumnLayout {
                Layout.fillWidth: true
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
}
