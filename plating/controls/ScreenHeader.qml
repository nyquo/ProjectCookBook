import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Plating

// A screen's header, in three layouts. At the top of the window it also pads
// itself out of the status bar (SafeArea).
T.Control {
    id: control

    enum Variant {
        // A tab's root screen: large title, optional action and controls under it
        TopLevel,
        // A screen pushed over another: a back button above the title
        Pushed,
        // A form: close, title and a primary action on one row
        Editor
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int variant: ScreenHeader.TopLevel
    property string title
    property string subtitle
    // On the title row: TopLevel, a large IconButton (e.g. settings); Pushed,
    // any item
    property Item trailing
    // Editor: the primary action
    property string actionText: qsTr("Save")
    property bool actionEnabled: true
    // TopLevel: the screen's own controls under the title, 12 apart
    default property alias content: slot.data

    signal backClicked
    signal closeClicked
    signal actionClicked

    readonly property bool topLevel: control.variant === ScreenHeader.TopLevel
    readonly property bool pushed: control.variant === ScreenHeader.Pushed
    readonly property bool editor: control.variant === ScreenHeader.Editor

    implicitWidth: implicitContentWidth + leftPadding + rightPadding
    implicitHeight: control.editor ? control.SafeArea.margins.top + UiMetrics.headerEditorHeight
                                   : implicitContentHeight + topPadding + bottomPadding

    topPadding: control.SafeArea.margins.top + (control.topLevel ? UiMetrics.headerTopPadding
                                                : control.pushed ? UiMetrics.headerPushedTopPadding
                                                                 : UiMetrics.headerEditorTopPadding)
    bottomPadding: control.topLevel ? UiMetrics.headerBottomPadding
                                    : control.pushed ? UiMetrics.headerPushedBottomPadding : 0
    leftPadding: control.SafeArea.margins.left + UiMetrics.space4
    rightPadding: control.SafeArea.margins.right + UiMetrics.space4

    contentItem: ColumnLayout {
        spacing: 0

        IconButton {
            visible: control.pushed
            icon.name: "back"
            text: qsTr("Back")
            onClicked: control.backClicked()
        }

        RowLayout {
            visible: !control.editor
            Layout.fillWidth: true
            Layout.topMargin: control.pushed ? UiMetrics.headerTitleGap : 0
            spacing: UiMetrics.space3

            Text {
                Layout.fillWidth: true
                leftPadding: control.topLevel ? UiMetrics.headerTitleInset : 0
                text: control.title
                font: UiTypography.titleXL
                lineHeightMode: Text.FixedHeight
                lineHeight: UiTypography.titleXL.pixelSize
                color: control.theme.ink
                wrapMode: Text.Wrap
                Accessible.role: Accessible.Heading
            }

            Item {
                visible: control.trailing !== null
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: control.trailing?.implicitWidth ?? 0
                implicitHeight: control.trailing?.implicitHeight ?? 0
                children: control.trailing ? [control.trailing] : []
            }
        }

        Text {
            visible: !control.editor && control.subtitle !== ""
            Layout.fillWidth: true
            Layout.topMargin: UiMetrics.headerSubtitleGap
            leftPadding: control.topLevel ? UiMetrics.headerTitleInset : 0
            text: control.subtitle
            font: UiTypography.bodyS
            lineHeightMode: Text.FixedHeight
            lineHeight: UiTypography.bodySLineHeight
            color: control.theme.inkMuted
            wrapMode: Text.Wrap
        }

        Column {
            id: slot

            visible: control.topLevel && slot.children.length > 0
            Layout.fillWidth: true
            Layout.topMargin: UiMetrics.headerSlotGap
            spacing: UiMetrics.headerSlotGap
        }

        RowLayout {
            visible: control.editor
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: UiMetrics.space3

            IconButton {
                icon.name: "close"
                text: qsTr("Close")
                onClicked: control.closeClicked()
            }

            Text {
                Layout.fillWidth: true
                text: control.title
                font: UiTypography.titleS
                color: control.theme.ink
                elide: Text.ElideRight
                Accessible.role: Accessible.Heading
            }

            Button {
                variant: Button.Primary
                size: Button.Small
                text: control.actionText
                enabled: control.actionEnabled
                onClicked: control.actionClicked()
            }
        }
    }
}
