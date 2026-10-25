pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A step of a recipe: its number, its text with the ingredients it mentions in
// bolder words, and the amounts it uses. While editing: the mentions are
// tokens, the amounts are chips, an add button and a drag handle follow, and a
// row under the card can insert a step. Editing the mentions isn't done here:
// the card shows the segments it's given.
T.Control {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    property bool editing: false
    // Editing: the card being edited, ringed in accent
    property bool selected: false
    // As given ("2")
    property string number
    // The text, as [{ text, ingredient }]: ingredient segments are mentions
    property var segments: []
    // [{ quantity, name }]
    property var amounts: []
    // Hides the amounts row and the bolder words
    property bool plain: false
    // Editing: a row under the card that emits insertClicked()
    property bool insertRow: false

    // The drag handle, for the caller's DragHandler
    readonly property Item dragHandle: handle
    readonly property string plainText: control.segments.map(segment => segment.text).join("")

    signal amountClicked(int index)
    signal addIngredientClicked
    signal insertClicked

    // The text as a flow of words, so a mention can be a token that wraps with
    // the words around it. Words only break at spaces.
    component WordFlow: Flow {
        id: flow

        readonly property bool tokens: control.editing
        readonly property bool strong: !control.editing && !control.plain
        readonly property real lineHeight: flow.tokens ? CookbookTypography.stepTextEditLineHeight
                                                       : UiTypography.bodyLLineHeight
        // [{ text, token, strong, gap }], gap: a space follows
        readonly property var words: {
            const words = []
            for (const segment of control.segments) {
                const startsWithSpace = /^\s/.test(segment.text)
                const endsWithSpace = /\s$/.test(segment.text)
                if (startsWithSpace && words.length > 0)
                    words[words.length - 1].gap = true
                if (segment.ingredient && flow.tokens) {
                    words.push({ text: segment.text.trim(), token: true, strong: false, gap: endsWithSpace })
                    continue
                }
                const pieces = segment.text.split(/\s+/).filter(piece => piece !== "")
                pieces.forEach((piece, index) => words.push({
                    text: piece,
                    token: false,
                    strong: segment.ingredient && flow.strong,
                    gap: index < pieces.length - 1 || endsWithSpace
                }))
            }
            return words
        }

        Accessible.role: Accessible.StaticText
        Accessible.name: control.plainText

        TextMetrics {
            id: space

            font: UiTypography.bodyL
            text: " "
        }

        Repeater {
            model: flow.words

            delegate: Item {
                id: word

                required property var modelData

                implicitWidth: (word.modelData.token ? token.width : label.implicitWidth)
                               + (word.modelData.gap ? space.advanceWidth : 0)
                implicitHeight: flow.lineHeight
                Accessible.ignored: true

                Text {
                    id: label

                    visible: !word.modelData.token
                    height: parent.height
                    text: word.modelData.text
                    font: word.modelData.strong ? UiTypography.bodyLStrong : UiTypography.bodyL
                    color: control.theme.ink
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    id: token

                    visible: word.modelData.token
                    anchors.verticalCenter: parent.verticalCenter
                    width: tokenText.implicitWidth + 2 * CookbookMetrics.stepTokenPadding
                    height: CookbookMetrics.stepTokenHeight
                    radius: height / 2
                    color: control.theme.accentSoft

                    Text {
                        id: tokenText

                        anchors.centerIn: parent
                        text: word.modelData.text
                        font: UiTypography.labelBold
                        color: control.theme.accent
                    }
                }
            }
        }
    }

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: implicitContentHeight + topPadding + bottomPadding

    opacity: control.enabled ? 1 : UiMetrics.opacityDisabled
    padding: 0

    contentItem: ColumnLayout {
        spacing: 0

        T.Control {
            id: card

            implicitWidth: implicitContentWidth + leftPadding + rightPadding
            implicitHeight: implicitContentHeight + topPadding + bottomPadding
            Layout.fillWidth: true
            topPadding: control.editing ? CookbookMetrics.stepCardEditPaddingV : CookbookMetrics.stepCardPadding
            bottomPadding: card.topPadding
            leftPadding: control.editing ? CookbookMetrics.stepCardEditPaddingStart : CookbookMetrics.stepCardPadding
            rightPadding: control.editing ? CookbookMetrics.stepCardEditPaddingEnd : CookbookMetrics.stepCardPadding

            contentItem: RowLayout {
                spacing: control.editing ? CookbookMetrics.stepCardEditGap : CookbookMetrics.stepCardGap

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    implicitWidth: control.editing ? CookbookMetrics.stepDiscEdit : CookbookMetrics.stepDisc
                    implicitHeight: implicitWidth
                    radius: width / 2
                    color: control.theme.accentSoft

                    Text {
                        anchors.centerIn: parent
                        text: control.number
                        font: control.editing ? UiTypography.titleS : CookbookTypography.stepNumber
                        color: control.theme.accent
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 0

                    WordFlow {
                        Layout.fillWidth: true
                        Layout.topMargin: control.editing ? 0 : CookbookMetrics.stepTextTop
                    }

                    Rectangle {
                        visible: !control.editing && !control.plain && control.amounts.length > 0
                        Layout.fillWidth: true
                        Layout.topMargin: CookbookMetrics.stepAmountsGap
                        Layout.bottomMargin: CookbookMetrics.stepAmountsGap
                        implicitHeight: UiMetrics.hairline
                        color: control.theme.line
                    }

                    // Read: amounts that wrap; lines stepAmountsLineGap apart,
                    // items stepAmountsItemGap apart
                    Flow {
                        visible: !control.editing && !control.plain && control.amounts.length > 0
                        Layout.fillWidth: true
                        spacing: CookbookMetrics.stepAmountsLineGap

                        Repeater {
                            model: control.editing ? [] : control.amounts

                            delegate: Row {
                                id: amountItem

                                required property var modelData

                                rightPadding: CookbookMetrics.stepAmountsItemGap - CookbookMetrics.stepAmountsLineGap
                                spacing: CookbookMetrics.stepAmountNameGap

                                QuantityPill {
                                    variant: QuantityPill.Small
                                    quantity: amountItem.modelData.quantity
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: amountItem.modelData.name
                                    font: UiTypography.labelS
                                    color: control.theme.ink
                                }
                            }
                        }
                    }

                    // Editing: amount chips and the add button
                    Flow {
                        visible: control.editing
                        Layout.fillWidth: true
                        Layout.topMargin: CookbookMetrics.stepAmountsGap
                        spacing: UiMetrics.space2

                        Repeater {
                            model: control.editing ? control.amounts : []

                            delegate: T.AbstractButton {
                                id: chip

                                required property int index
                                required property var modelData

                                implicitWidth: implicitContentWidth + leftPadding + rightPadding
                                implicitHeight: CookbookMetrics.stepAmountChipHeight
                                leftPadding: CookbookMetrics.stepAmountChipPaddingStart
                                rightPadding: CookbookMetrics.stepAmountChipPaddingEnd
                                text: chip.modelData.name
                                Accessible.role: Accessible.Button
                                Accessible.name: `${chip.modelData.quantity} ${chip.modelData.name}`
                                onClicked: control.amountClicked(chip.index)

                                contentItem: RowLayout {
                                    spacing: CookbookMetrics.stepAmountNameGap

                                    QuantityPill {
                                        variant: QuantityPill.Small
                                        implicitHeight: CookbookMetrics.stepAmountPillHeight
                                        quantity: chip.modelData.quantity
                                    }

                                    Text {
                                        text: chip.text
                                        font: UiTypography.labelS
                                        color: control.theme.ink
                                    }
                                }

                                background: Rectangle {
                                    radius: height / 2
                                    color: control.theme.bg

                                    PressOverlay {
                                        radius: parent.radius
                                        pressed: chip.down
                                    }

                                    FocusRing {
                                        visible: chip.visualFocus
                                        targetRadius: parent.radius
                                    }
                                }
                            }
                        }

                        Button {
                            variant: Button.Quiet
                            size: Button.ExtraSmall
                            inset: true
                            add: true
                            text: qsTr("Ingredient")
                            onClicked: control.addIngredientClicked()
                        }
                    }
                }

                Item {
                    id: handle

                    visible: control.editing
                    Layout.fillHeight: true
                    implicitWidth: CookbookMetrics.stepHandleWidth
                    Accessible.name: qsTr("Move")

                    Icon {
                        anchors.centerIn: parent
                        width: UiMetrics.iconL
                        height: UiMetrics.iconL
                        name: "drag"
                        color: control.theme.inkMuted
                    }
                }
            }

            background: Rectangle {
                radius: UiMetrics.radiusMd
                color: control.theme.surface
                border.width: control.editing && control.selected ? UiMetrics.borderStrong : 0
                border.color: control.theme.accent
            }
        }

        // Between cards: inserts a step
        Item {
            visible: control.editing && control.insertRow
            Layout.fillWidth: true
            implicitHeight: CookbookMetrics.stepInsertHeight

            T.AbstractButton {
                id: insert

                anchors.verticalCenter: parent.verticalCenter
                x: CookbookMetrics.stepCardEditPaddingStart
                   + (CookbookMetrics.stepDiscEdit - CookbookMetrics.stepInsertDisc) / 2
                width: CookbookMetrics.stepInsertDisc
                height: CookbookMetrics.stepInsertDisc
                containmentMask: TouchTarget {
                    target: insert
                }
                Accessible.role: Accessible.Button
                Accessible.name: qsTr("Insert a step")
                onClicked: control.insertClicked()

                contentItem: Item {
                    Icon {
                        anchors.centerIn: parent
                        width: UiMetrics.iconM
                        height: UiMetrics.iconM
                        name: "plus"
                        color: control.theme.inkMuted
                    }
                }

                background: Item {
                    DashedOutline {
                        anchors.fill: parent
                        color: control.theme.line
                        strokeWidth: UiMetrics.hairline
                        radius: width / 2
                    }

                    PressOverlay {
                        radius: width / 2
                        pressed: insert.down
                    }

                    FocusRing {
                        visible: insert.visualFocus
                        targetRadius: width / 2
                    }
                }
            }
        }
    }
}
