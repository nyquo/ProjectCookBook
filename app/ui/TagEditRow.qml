pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A tag in the tags editor, usually in a ListGroup. Closed: the tag as a pill,
// how many recipes carry it and a chevron; clicking it emits openClicked().
// Open: an inset panel with its name, its color, what uses it, Delete and
// Done. Controlled: the caller sets `open`, `name` and `colorIndex`. When the
// name's editing ends, renamed() gives the new name; the field then shows
// `name` again, whether the caller saved it or not.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property string name
    // The tag's family: the pill's fill and ink
    property colorFamily family
    // As given: "3 recipes"
    property string countText
    // As given: "Used by 3 recipes"
    property string usageText
    property bool open: false
    // The colors to pick from: [{ name, family }]
    property var colors: []
    // The checked color's index, or -1
    property int colorIndex: -1

    signal openClicked
    signal renamed(string name)
    signal colorClicked(int index)
    signal deleteClicked
    signal doneClicked

    // A label above a part of the panel
    component PartLabel: Text {
        leftPadding: UiMetrics.textFieldLabelInset
        font: UiTypography.overline
        color: control.theme.inkMuted
        elide: Text.ElideRight
    }

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    padding: 0
    topPadding: control.open ? CookbookMetrics.tagPanelMarginV : 0
    bottomPadding: control.topPadding

    contentItem: Item {
        implicitWidth: control.open ? panel.implicitWidth : closed.implicitWidth
        implicitHeight: control.open ? panel.implicitHeight : closed.implicitHeight

        ListRow {
            id: closed

            width: parent.width
            visible: !control.open
            implicitHeight: Math.max(CookbookMetrics.tagRowHeight, implicitContentHeight + topPadding + bottomPadding)
            value: control.countText
            leading: TagPill {
                size: TagPill.Large
                font: UiTypography.labelSBold
                text: control.name
                family: control.family
            }
            trailing: Icon {
                implicitWidth: CookbookMetrics.tagRowChevron
                implicitHeight: CookbookMetrics.tagRowChevron
                source: CookbookIcons.source("chevron-right")
                color: control.theme.inkMuted
            }
            Accessible.name: control.name
            Accessible.description: control.countText
            onClicked: control.openClicked()
        }

        Rectangle {
            id: panel

            width: parent.width
            implicitWidth: parts.implicitWidth + 2 * CookbookMetrics.tagPanelPaddingH
            implicitHeight: parts.implicitHeight + 2 * CookbookMetrics.tagPanelPaddingV
            height: implicitHeight
            visible: control.open
            radius: CookbookMetrics.tagPanelRadius
            color: control.theme.bg

            ColumnLayout {
                id: parts

                x: CookbookMetrics.tagPanelPaddingH
                y: CookbookMetrics.tagPanelPaddingV
                width: parent.width - 2 * CookbookMetrics.tagPanelPaddingH
                spacing: CookbookMetrics.tagPanelGap

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: UiMetrics.textFieldLabelGap

                    PartLabel {
                        Layout.fillWidth: true
                        text: qsTr("Name")
                    }

                    TextField {
                        id: nameField

                        Layout.fillWidth: true
                        implicitHeight: CookbookMetrics.tagNameFieldHeight
                        font: UiTypography.labelLBold
                        Accessible.name: qsTr("Tag name")

                        // Shows `name` again once editing ends
                        Binding on text {
                            when: !nameField.activeFocus
                            value: control.name
                        }

                        onEditingFinished: {
                            if (nameField.text !== control.name)
                                control.renamed(nameField.text)
                        }
                        onAccepted: nameField.focus = false
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: UiMetrics.textFieldLabelGap

                    PartLabel {
                        Layout.fillWidth: true
                        text: qsTr("Color")
                    }

                    // Spread across the width
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: control.colors

                            delegate: Item {
                                id: cell

                                required property var modelData
                                required property int index

                                Layout.fillWidth: true
                                implicitWidth: dot.implicitWidth
                                implicitHeight: dot.implicitHeight

                                ColorDot {
                                    id: dot

                                    anchors.centerIn: parent
                                    size: ColorDot.Large
                                    text: cell.modelData.name
                                    family: cell.modelData.family
                                    checked: cell.index === control.colorIndex
                                    onClicked: control.colorClicked(cell.index)
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    leftPadding: UiMetrics.textFieldLabelInset
                    text: control.usageText
                    font: UiTypography.caption
                    lineHeightMode: Text.FixedHeight
                    lineHeight: UiTypography.captionLineHeight
                    color: control.theme.inkMuted
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: UiMetrics.space2

                    Button {
                        variant: Button.Text
                        size: Button.Small
                        destructive: true
                        icon.source: CookbookIcons.source("trash")
                        icon.width: CookbookMetrics.tagDeleteIcon
                        icon.height: CookbookMetrics.tagDeleteIcon
                        text: qsTr("Delete tag")
                        onClicked: control.deleteClicked()
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        variant: Button.Secondary
                        size: Button.Small
                        text: qsTr("Done")
                        onClicked: control.doneClicked()
                    }
                }
            }
        }
    }
}
