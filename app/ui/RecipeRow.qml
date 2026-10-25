pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A recipe in the list: thumbnail, name (with a heart if it's a favorite), up
// to two tags, then its time and when it was last cooked. Clicked opens it;
// pressAndHold() asks for its quick actions.
T.ItemDelegate {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property url thumbnail
    property string initials
    // The thumbnail's family when there's no picture
    property colorFamily family
    property bool favorite: false
    // [{ name, family }]; two at most are shown
    property var tags: []
    // As given ("1 h 15", "3 weeks ago")
    property string time
    property string lastCooked

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topPadding: CookbookMetrics.recipeRowPaddingV
    bottomPadding: CookbookMetrics.recipeRowPaddingV
    leftPadding: CookbookMetrics.recipeRowPaddingH
    rightPadding: CookbookMetrics.recipeRowPaddingH
    spacing: CookbookMetrics.recipeRowGap
    font: UiTypography.titleM

    contentItem: RowLayout {
        spacing: control.spacing

        Thumbnail {
            source: control.thumbnail
            initials: control.initials
            family: control.family
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: CookbookMetrics.recipeRowTagsTop

            // The name at its own width, the heart right after it
            Item {
                id: titleRow

                Layout.fillWidth: true
                implicitWidth: title.implicitWidth + (heart.visible ? heart.width + UiMetrics.space1 : 0)
                implicitHeight: title.implicitHeight

                Text {
                    id: title

                    width: Math.min(implicitWidth, titleRow.width - (heart.visible ? heart.width + UiMetrics.space1 : 0))
                    text: control.text
                    font: control.font
                    color: control.theme.ink
                    elide: Text.ElideRight
                }

                Icon {
                    id: heart

                    x: title.width + UiMetrics.space1
                    anchors.verticalCenter: title.verticalCenter
                    width: UiMetrics.iconXS
                    height: UiMetrics.iconXS
                    visible: control.favorite
                    name: "heart"
                    filled: true
                    color: control.theme.accent
                    Accessible.name: qsTr("Favorite")
                }
            }

            Row {
                visible: control.tags.length > 0
                spacing: CookbookMetrics.recipeRowTagGap

                Repeater {
                    model: control.tags.slice(0, 2)

                    delegate: TagPill {
                        required property var modelData

                        text: modelData.name
                        family: modelData.family
                    }
                }
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignTop | Qt.AlignRight
            spacing: 0

            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: UiMetrics.space1

                Icon {
                    Layout.preferredWidth: UiMetrics.iconXS
                    Layout.preferredHeight: UiMetrics.iconXS
                    name: "clock"
                    color: control.theme.inkMuted
                }

                Text {
                    text: control.time
                    font: UiTypography.tabular(UiTypography.labelSBold)
                    color: control.theme.ink
                }
            }

            Text {
                Layout.alignment: Qt.AlignRight
                visible: control.lastCooked !== ""
                text: control.lastCooked
                font: UiTypography.tabular(UiTypography.caption)
                color: control.theme.inkMuted
            }
        }
    }

    background: Rectangle {
        color: control.theme.surface

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: UiMetrics.hairline
            color: control.theme.line
        }

        PressOverlay {
            pressed: control.down
        }

        FocusRing {
            visible: control.visualFocus
            anchors.margins: 0
            border.width: UiMetrics.focusRingWidth
        }
    }
}
