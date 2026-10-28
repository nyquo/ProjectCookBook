pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// An ingredient of a recipe, in its ingredients card: quantity, name, note,
// and a Substitute link that expands the alternatives. While editing: a drag
// handle, how it's on the shopping list, which steps use it, and a more
// button.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property bool editing: false
    // As given; "" shows "To taste"
    property string quantity
    property string name
    property bool optional: false
    property string note
    // As given ("or 200 g crème fraîche"); a Substitute link shows them,
    // "Substitutes" when there are several
    property var alternatives: []
    property bool expanded: false
    // Editing: "On the list as Garlic"
    property string linkedText
    // Editing: "Steps 2 and 4", or "Not in a step yet" when unused
    property string usageText
    property bool usedInSteps: true

    // The drag handle, for the caller's DragHandler
    readonly property Item dragHandle: handle

    signal moreClicked

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: Math.max(control.editing ? CookbookMetrics.ingredientRowEditHeight : 0,
                             implicitContentHeight + topPadding + bottomPadding)

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    topPadding: CookbookMetrics.ingredientRowPaddingV
    bottomPadding: CookbookMetrics.ingredientRowPaddingV
    leftPadding: 0
    rightPadding: 0
    spacing: control.editing ? CookbookMetrics.ingredientRowEditGap : CookbookMetrics.ingredientRowGap

    // An icon and a short line of text
    component MetaLine: RowLayout {
        id: line

        property string iconName
        property color color
        property alias text: label.text
        property alias font: label.font

        spacing: UiMetrics.space1

        Icon {
            Layout.preferredWidth: UiMetrics.iconXS
            Layout.preferredHeight: UiMetrics.iconXS
            name: line.iconName
            color: line.color
        }

        Text {
            id: label

            Layout.fillWidth: true
            color: line.color
            elide: Text.ElideRight
        }
    }

    contentItem: RowLayout {
        spacing: control.spacing

        Item {
            id: handle

            visible: control.editing
            implicitWidth: CookbookMetrics.ingredientRowHandle
            implicitHeight: CookbookMetrics.ingredientRowHandle
            Accessible.name: qsTr("Move")

            Icon {
                anchors.fill: parent
                name: "drag"
                color: control.theme.inkMuted
            }
        }

        QuantityPill {
            Layout.alignment: control.editing ? Qt.AlignVCenter : Qt.AlignTop
            quantity: control.quantity
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: control.editing ? Qt.AlignVCenter : Qt.AlignTop
            spacing: 0

            // The name at its own width, "(optional)" right after it
            Item {
                id: nameRow

                Layout.fillWidth: true
                implicitWidth: nameText.implicitWidth + (optionalText.visible ? optionalText.implicitWidth + UiMetrics.space1 : 0)
                implicitHeight: nameText.implicitHeight

                Text {
                    id: nameText

                    width: Math.min(implicitWidth, nameRow.width - (optionalText.visible ? optionalText.implicitWidth
                                                                                          + UiMetrics.space1 : 0))
                    text: control.name
                    font: UiTypography.labelL
                    color: control.theme.ink
                    elide: Text.ElideRight
                }

                Text {
                    id: optionalText

                    x: nameText.width + UiMetrics.space1
                    anchors.baseline: nameText.baseline
                    visible: control.optional
                    text: qsTr("(optional)")
                    font: UiTypography.caption
                    color: control.theme.inkMuted
                }
            }

            Text {
                visible: control.note !== ""
                Layout.fillWidth: true
                text: control.note
                font: control.editing ? UiTypography.caption : UiTypography.bodyS
                color: control.theme.inkMuted
                wrapMode: Text.Wrap
            }

            MetaLine {
                visible: control.editing && control.linkedText !== ""
                Layout.fillWidth: true
                iconName: "link"
                text: control.linkedText
                font: UiTypography.overline
                color: control.theme.inkMuted
            }

            MetaLine {
                visible: control.editing && control.usageText !== ""
                Layout.fillWidth: true
                iconName: control.usedInSteps ? "check" : "dot"
                text: control.usageText
                font: UiTypography.tag
                color: control.usedInSteps ? control.theme.inkMuted : control.theme.accent
            }

            T.AbstractButton {
                id: substitute

                visible: !control.editing && control.alternatives.length > 0
                implicitWidth: implicitContentWidth
                implicitHeight: CookbookMetrics.substituteHeight
                text: control.alternatives.length > 1 ? qsTr("Substitutes") : qsTr("Substitute")
                Accessible.role: Accessible.Button
                Accessible.name: substitute.text
                onClicked: control.expanded = !control.expanded

                contentItem: RowLayout {
                    spacing: UiMetrics.space1

                    Text {
                        text: substitute.text
                        font: UiTypography.labelSBold
                        color: control.theme.accent
                    }

                    Icon {
                        Layout.preferredWidth: CookbookMetrics.substituteIcon
                        Layout.preferredHeight: CookbookMetrics.substituteIcon
                        name: "chevron-down"
                        color: control.theme.accent
                        rotation: control.expanded ? 180 : 0

                        Behavior on rotation {
                            NumberAnimation {
                                duration: UiMotion.move(UiMotion.toggle)
                                easing.type: Easing.Bezier
                                easing.bezierCurve: UiMotion.decelerate
                            }
                        }
                    }
                }

                background: Item {
                    FocusRing {
                        visible: substitute.visualFocus
                        targetRadius: UiMetrics.radiusSm
                    }
                }
            }

            Repeater {
                model: !control.editing && control.expanded ? control.alternatives : []

                delegate: Text {
                    required property string modelData

                    Layout.fillWidth: true
                    text: modelData
                    font: UiTypography.bodyS
                    color: control.theme.inkMuted
                    wrapMode: Text.Wrap
                }
            }
        }

        IconButton {
            visible: control.editing
            size: IconButton.Small
            variant: IconButton.Ghost
            icon.name: "more"
            text: qsTr("More")
            onClicked: control.moreClicked()
        }
    }

    background: Item {
        Rectangle {
            width: parent.width
            height: UiMetrics.hairline
            color: control.theme.line
        }
    }
}
