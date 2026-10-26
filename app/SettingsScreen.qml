pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// The settings: appearance, units, the recipes list's default filters, the way
// into the shopping catalog, the recipe fields shown, cooking, and the way into
// the tags editor
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
    readonly property list<int> unitSystems: [
        UnitSettings.System.Metric,
        UnitSettings.System.Us
    ]
    // What the recipes list opens with, as the default filters card says it
    readonly property string defaultFiltersText: {
        const favorites = DefaultFilterSettings.favoritesOnly
        const tagNames = DefaultFilterSettings.tagNames
        if (favorites && tagNames !== "")
            return qsTr("The recipes list opens showing only your favorites tagged %1. You can still change filters from the list.").arg(tagNames)
        if (favorites)
            return qsTr("The recipes list opens showing only your favorites. You can still change filters from the list.")
        if (tagNames !== "")
            return qsTr("The recipes list opens showing only %1. You can still change filters from the list.").arg(tagNames)
        return qsTr("The recipes list opens with all recipes.")
    }
    readonly property real sideMargin: UiMetrics.space4

    AisleListModel {
        id: aisles
    }

    CatalogListModel {
        id: catalog
    }

    TagListModel {
        id: tags
    }

    Component {
        id: catalogScreen

        CatalogScreen {}
    }

    Component {
        id: tagsScreen

        TagsScreen {}
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

    // A caption inside a card
    component CardCaption: Text {
        font: UiTypography.caption
        lineHeightMode: Text.FixedHeight
        lineHeight: UiTypography.captionLineHeight
        color: screen.theme.inkMuted
        wrapMode: Text.Wrap
    }

    // A caption under a card
    component Caption: CardCaption {
        Layout.fillWidth: true
        Layout.topMargin: CookbookMetrics.settingsCaptionGap
        leftPadding: CookbookMetrics.settingsCaptionInset
        rightPadding: CookbookMetrics.settingsCaptionInset
    }

    // A row that ends with a switch, named after the row's title; clicking the
    // row toggles it. Controlled: switched() gives the new state.
    component SwitchRow: ListRow {
        id: switchRow

        property bool switchedOn

        signal switched(bool toggledOn)

        trailing: Switch {
            checked: switchRow.switchedOn
            Accessible.name: switchRow.text
            onToggled: switchRow.switched(checked)
        }
    }

    // A recipe field to show or hide
    component FieldRow: SwitchRow {
        implicitHeight: Math.max(CookbookMetrics.settingsFieldRowHeight, implicitContentHeight + topPadding + bottomPadding)
    }

    component Chevron: Icon {
        implicitWidth: CookbookMetrics.settingsChevron
        implicitHeight: CookbookMetrics.settingsChevron
        source: CookbookIcons.source("chevron-right")
        color: screen.theme.inkMuted
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

                                CardCaption {
                                    Layout.fillWidth: true
                                    text: qsTr("Changes buttons and highlights. Tag colors stay as they are.")
                                }
                            }
                        }
                    }
                }

                Section {
                    title: qsTr("Units")

                    Card {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: CookbookMetrics.settingsUnitsGap

                            RowTitle {
                                Layout.fillWidth: true
                                text: qsTr("Unit system")
                            }

                            SegmentedControl {
                                Layout.fillWidth: true
                                currentIndex: screen.unitSystems.indexOf(UnitSettings.system)
                                onCurrentIndexChanged: {
                                    if (currentIndex >= 0)
                                        UnitSettings.system = screen.unitSystems[currentIndex]
                                }

                                SegmentedButton {
                                    text: qsTr("Metric")
                                    detail: qsTr("g, kg, ml, l")
                                }
                                SegmentedButton {
                                    text: qsTr("US")
                                    detail: qsTr("oz, lb, cup, fl oz")
                                }
                            }

                            CardCaption {
                                Layout.fillWidth: true
                                text: qsTr("What you typed is kept as is; only the display is converted.")
                            }
                        }
                    }
                }

                Section {
                    title: qsTr("Default filters")

                    Card {
                        Layout.fillWidth: true
                        topPadding: CookbookMetrics.settingsFiltersPaddingTop

                        ColumnLayout {
                            spacing: 0

                            SwitchRow {
                                Layout.fillWidth: true
                                text: qsTr("Favorites only")
                                switchedOn: DefaultFilterSettings.favoritesOnly
                                onSwitched: toggledOn => DefaultFilterSettings.favoritesOnly = toggledOn
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: UiMetrics.hairline
                                color: screen.theme.line
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: CookbookMetrics.settingsFiltersGap
                                spacing: CookbookMetrics.settingsFiltersGap

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Tags")
                                    font: UiTypography.labelL
                                    color: screen.theme.ink
                                    elide: Text.ElideRight
                                    Accessible.role: Accessible.Heading
                                }

                                Flow {
                                    id: chips

                                    Layout.fillWidth: true
                                    visible: tags.count > 0
                                    spacing: CookbookMetrics.settingsTagGap

                                    Repeater {
                                        model: tags

                                        delegate: TagChip {
                                            id: chip

                                            required property string tagId
                                            required property string name
                                            required property string colorKey

                                            width: Math.min(implicitWidth, chips.width)
                                            text: chip.name
                                            family: TagFamilies.family(screen.theme, chip.colorKey)
                                            inset: true
                                            checkable: false
                                            checked: DefaultFilterSettings.tagIds.includes(chip.tagId)
                                            Accessible.role: Accessible.CheckBox
                                            Accessible.checkable: true
                                            Accessible.checked: chip.checked
                                            onClicked: DefaultFilterSettings.setTagSelected(chip.tagId, !chip.checked)
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: tags.count === 0
                                    spacing: UiMetrics.space3

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("No tags yet.")
                                        font: UiTypography.bodyS
                                        color: screen.theme.inkMuted
                                        elide: Text.ElideRight
                                    }

                                    Button {
                                        variant: Button.Text
                                        size: Button.Small
                                        text: qsTr("Manage tags")
                                        onClicked: screen.StackView.view.push(tagsScreen)
                                    }
                                }

                                CardCaption {
                                    Layout.fillWidth: true
                                    text: screen.defaultFiltersText
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

                Section {
                    title: qsTr("Recipe fields")

                    ListGroup {
                        Layout.fillWidth: true

                        FieldRow {
                            text: qsTr("Cost")
                            subtitle: qsTr("Price of the recipe and per serving")
                            switchedOn: RecipeFieldSettings.cost
                            onSwitched: toggledOn => RecipeFieldSettings.cost = toggledOn
                        }
                        FieldRow {
                            text: qsTr("Prep and cook times")
                            subtitle: qsTr("Shown in the list and on the recipe")
                            switchedOn: RecipeFieldSettings.times
                            onSwitched: toggledOn => RecipeFieldSettings.times = toggledOn
                        }
                        FieldRow {
                            text: qsTr("Amounts in steps")
                            subtitle: qsTr("At the bottom of each step")
                            switchedOn: RecipeFieldSettings.stepAmounts
                            onSwitched: toggledOn => RecipeFieldSettings.stepAmounts = toggledOn
                        }
                        FieldRow {
                            text: qsTr("Cooking history")
                            subtitle: qsTr("Times cooked and last cooked date")
                            switchedOn: RecipeFieldSettings.cookingHistory
                            onSwitched: toggledOn => RecipeFieldSettings.cookingHistory = toggledOn
                        }
                        FieldRow {
                            text: qsTr("Source")
                            subtitle: qsTr("Link, book or person")
                            switchedOn: RecipeFieldSettings.source
                            onSwitched: toggledOn => RecipeFieldSettings.source = toggledOn
                        }
                        FieldRow {
                            text: qsTr("Notes")
                            subtitle: qsTr("Your personal notes")
                            switchedOn: RecipeFieldSettings.notes
                            onSwitched: toggledOn => RecipeFieldSettings.notes = toggledOn
                        }
                    }

                    Caption {
                        text: qsTr("A hidden field disappears from the list, the recipe and the editor. What you already entered is kept.")
                    }
                }

                Section {
                    title: qsTr("Cooking")

                    ListGroup {
                        Layout.fillWidth: true

                        SwitchRow {
                            text: qsTr("Keep screen on")
                            subtitle: qsTr("While a recipe is open")
                            switchedOn: CookingSettings.keepScreenOn
                            onSwitched: toggledOn => CookingSettings.keepScreenOn = toggledOn
                        }
                    }
                }

                Section {
                    title: qsTr("Tags")

                    ListGroup {
                        Layout.fillWidth: true
                        rightPadding: UiMetrics.space3

                        ListRow {
                            text: qsTr("Manage tags")
                            value: qsTr("%Ln tag(s)", "", tags.count)
                            trailing: Chevron {}
                            onClicked: screen.StackView.view.push(tagsScreen)
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
