pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

// The showcase's own toolbar: light or dark, the accent, reduced motion. It
// sits at the top of the window, under the status bar.
Rectangle {
    id: bar

    readonly property UiTheme theme: Plating.theme as UiTheme

    implicitHeight: bar.SafeArea.margins.top + flick.height + UiMetrics.hairline
    color: bar.theme.surface

    ScrollArea {
        id: flick

        y: bar.SafeArea.margins.top
        x: bar.SafeArea.margins.left
        width: parent.width - bar.SafeArea.margins.left - bar.SafeArea.margins.right
        height: row.implicitHeight + 2 * UiMetrics.space1
        contentWidth: row.implicitWidth + 2 * UiMetrics.space4
        orientation: Qt.Horizontal
        clip: true

        RowLayout {
            id: row

            x: UiMetrics.space4
            y: UiMetrics.space1
            spacing: UiMetrics.space2

            // Toggles: secondary while on
            Button {
                variant: ShowcaseState.dark ? Button.Secondary : Button.Quiet
                inset: true
                size: Button.ExtraSmall
                text: qsTr("Dark")
                onClicked: ShowcaseState.dark = !ShowcaseState.dark
            }

            Button {
                variant: ShowcaseState.reducedMotion ? Button.Secondary : Button.Quiet
                inset: true
                size: Button.ExtraSmall
                text: qsTr("Reduce motion")
                onClicked: ShowcaseState.reducedMotion = !ShowcaseState.reducedMotion
            }

            Repeater {
                model: [
                    { name: qsTr("Raspberry"), value: UiTheme.Raspberry },
                    { name: qsTr("Spirulina"), value: UiTheme.Spirulina },
                    { name: qsTr("Blueberry"), value: UiTheme.Blueberry },
                    { name: qsTr("Saffron"), value: UiTheme.Saffron },
                    { name: qsTr("Basil"), value: UiTheme.Basil }
                ]

                delegate: ColorSwatch {
                    required property string name
                    required property int value

                    text: name
                    family: {
                        switch (value) {
                        case UiTheme.Spirulina:
                            return { fill: bar.theme.accentSpirulina, ink: bar.theme.accentSpirulinaInk }
                        case UiTheme.Blueberry:
                            return { fill: bar.theme.accentBlueberry, ink: bar.theme.accentBlueberryInk }
                        case UiTheme.Saffron:
                            return { fill: bar.theme.accentSaffron, ink: bar.theme.accentSaffronInk }
                        case UiTheme.Basil:
                            return { fill: bar.theme.accentBasil, ink: bar.theme.accentBasilInk }
                        default:
                            return { fill: bar.theme.accentRaspberry, ink: bar.theme.accentRaspberryInk }
                        }
                    }
                    checked: ShowcaseState.accent === value
                    onClicked: ShowcaseState.accent = value
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: UiMetrics.hairline
        color: bar.theme.line
    }
}
