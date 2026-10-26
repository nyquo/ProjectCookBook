pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// The settings: appearance, and the way into the shopping catalog
AppScreen {
    id: screen

    // In UiTheme.Accent order
    readonly property var accents: [
        {
            name: qsTr("Raspberry"),
            value: AppearanceSettings.Accent.Raspberry,
            family: { fill: screen.theme.accentRaspberry, ink: screen.theme.accentRaspberryInk }
        },
        {
            name: qsTr("Spirulina"),
            value: AppearanceSettings.Accent.Spirulina,
            family: { fill: screen.theme.accentSpirulina, ink: screen.theme.accentSpirulinaInk }
        },
        {
            name: qsTr("Blueberry"),
            value: AppearanceSettings.Accent.Blueberry,
            family: { fill: screen.theme.accentBlueberry, ink: screen.theme.accentBlueberryInk }
        },
        {
            name: qsTr("Saffron"),
            value: AppearanceSettings.Accent.Saffron,
            family: { fill: screen.theme.accentSaffron, ink: screen.theme.accentSaffronInk }
        },
        {
            name: qsTr("Basil"),
            value: AppearanceSettings.Accent.Basil,
            family: { fill: screen.theme.accentBasil, ink: screen.theme.accentBasilInk }
        }
    ]
    // The segments' order
    readonly property list<int> themeModes: [
        AppearanceSettings.ThemeMode.Light,
        AppearanceSettings.ThemeMode.Dark,
        AppearanceSettings.ThemeMode.System
    ]
    readonly property real sideMargin: UiMetrics.space4

    AisleListModel {
        id: aisles
    }

    CatalogListModel {
        id: catalog
    }

    Component {
        id: catalogScreen

        CatalogScreen {}
    }

    // A section's label, then its content
    component Section: ColumnLayout {
        property alias title: header.text

        Layout.fillWidth: true
        spacing: 0

        SectionHeader {
            id: header

            Layout.fillWidth: true
        }
    }

    // A label in a card
    component RowTitle: Text {
        font: UiTypography.labelLBold
        color: screen.theme.ink
        elide: Text.ElideRight
        Accessible.role: Accessible.Heading
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScreenHeader {
            Layout.fillWidth: true
            variant: ScreenHeader.Pushed
            title: qsTr("Settings")
            onBackClicked: screen.StackView.view.pop()
        }

        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: body.implicitHeight + body.anchors.topMargin + body.anchors.bottomMargin
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            ColumnLayout {
                id: body

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.topMargin: UiMetrics.space4
                anchors.bottomMargin: UiMetrics.space8 + screen.SafeArea.margins.bottom
                anchors.leftMargin: screen.sideMargin + screen.SafeArea.margins.left
                anchors.rightMargin: screen.sideMargin + screen.SafeArea.margins.right
                spacing: CookbookMetrics.settingsSectionGap

                Section {
                    title: qsTr("Appearance")

                    Card {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: CookbookMetrics.settingsRowGap

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: CookbookMetrics.settingsLabelGap

                                RowTitle {
                                    Layout.fillWidth: true
                                    text: qsTr("Theme")
                                }

                                SegmentedControl {
                                    Layout.fillWidth: true
                                    currentIndex: screen.themeModes.indexOf(AppearanceSettings.themeMode)
                                    onCurrentIndexChanged: {
                                        if (currentIndex >= 0)
                                            AppearanceSettings.themeMode = screen.themeModes[currentIndex]
                                    }

                                    SegmentedButton {
                                        text: qsTr("Light")
                                        icon.source: CookbookIcons.source("sun")
                                    }
                                    SegmentedButton {
                                        text: qsTr("Dark")
                                        icon.source: CookbookIcons.source("moon")
                                    }
                                    SegmentedButton {
                                        text: qsTr("System")
                                        icon.source: CookbookIcons.source("phone")
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: CookbookMetrics.settingsLabelGap

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: UiMetrics.space3

                                    RowTitle {
                                        Layout.fillWidth: true
                                        text: qsTr("Accent color")
                                    }

                                    Text {
                                        text: screen.accents.find(a => a.value === AppearanceSettings.accent)?.name ?? ""
                                        font: UiTypography.bodyS
                                        color: screen.theme.inkMuted
                                    }
                                }

                                // Spread across the width
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Repeater {
                                        model: screen.accents

                                        delegate: Item {
                                            id: cell

                                            required property var modelData

                                            Layout.fillWidth: true
                                            implicitWidth: CookbookMetrics.accentSwatch
                                            implicitHeight: CookbookMetrics.accentSwatch

                                            ColorSwatch {
                                                anchors.centerIn: parent
                                                implicitWidth: CookbookMetrics.accentSwatch
                                                implicitHeight: CookbookMetrics.accentSwatch
                                                text: cell.modelData.name
                                                family: cell.modelData.family
                                                checkable: false
                                                checked: AppearanceSettings.accent === cell.modelData.value
                                                onClicked: AppearanceSettings.accent = cell.modelData.value
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Changes buttons and highlights. Tag colors stay as they are.")
                                    font: UiTypography.caption
                                    lineHeightMode: Text.FixedHeight
                                    lineHeight: UiTypography.captionLineHeight
                                    color: screen.theme.inkMuted
                                    wrapMode: Text.Wrap
                                }
                            }
                        }
                    }
                }

                Section {
                    title: qsTr("Shopping")

                    ListGroup {
                        Layout.fillWidth: true
                        rightPadding: UiMetrics.space3

                        ListRow {
                            text: qsTr("Ingredient catalog")
                            subtitle: qsTr("%1 in %2").arg(qsTr("%Ln item(s)", "", catalog.count))
                                                      .arg(qsTr("%Ln aisle(s)", "", aisles.count))
                            strong: true
                            leading: IconDiscStack {
                                discs: [
                                    {
                                        iconSource: IngredientIcons.source("carrot"),
                                        family: { fill: screen.theme.tagMint, ink: screen.theme.tagMintInk }
                                    },
                                    {
                                        iconSource: IngredientIcons.source("cheese"),
                                        family: { fill: screen.theme.tagButter, ink: screen.theme.tagButterInk }
                                    },
                                    {
                                        iconSource: IngredientIcons.source("sack"),
                                        family: { fill: screen.theme.tagSky, ink: screen.theme.tagSkyInk }
                                    }
                                ]
                            }
                            trailing: Icon {
                                implicitWidth: UiMetrics.iconL
                                implicitHeight: UiMetrics.iconL
                                source: CookbookIcons.source("chevron-right")
                                color: screen.theme.inkMuted
                            }
                            onClicked: screen.StackView.view.push(catalogScreen)
                        }
                    }
                }

                // Which build is running
                Text {
                    Layout.fillWidth: true
                    text: `${AppInfo.name} · ${AppInfo.platform} · ${AppInfo.cpuArchitecture} · `
                          + qsTr("v%1 · Qt %2").arg(AppInfo.version).arg(AppInfo.qtVersion)
                    font: UiTypography.caption
                    lineHeightMode: Text.FixedHeight
                    lineHeight: UiTypography.captionLineHeight
                    color: screen.theme.inkMuted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
