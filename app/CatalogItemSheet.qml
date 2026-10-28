pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

// Adds an item to the catalog, or edits one: its name, its aisle (possibly a
// new one), its icon and what one tap adds
BottomSheet {
    id: sheet

    required property CatalogListModel catalog
    required property AisleListModel aisles

    // "" while adding
    property string ingredientId
    // The name the item had when the sheet opened
    property string originalName
    property string aisleId
    // An IngredientIcons name, or "" for none
    property string icon
    property real quantity: 1
    property string unit: "pcs"
    property bool addingAisle: false

    readonly property bool editing: sheet.ingredientId !== ""
    readonly property int nameStatus: sheet.catalog.checkName(nameField.text, sheet.ingredientId)
    // The chosen aisle's family, as its chip shows it
    readonly property colorFamily family: {
        for (let i = 0; i < aisleChoices.count; ++i) {
            const choice = aisleChoices.itemAt(i) as AisleChoice
            if (choice && choice.aisleId === sheet.aisleId)
                return choice.family
        }
        return { fill: sheet.theme.bg, ink: sheet.theme.inkMuted }
    }
    // Every unit, for QuantityField; `initial` is the amount a unit of another
    // kind starts at. US units have kinds of their own: switching between
    // systems starts over rather than leaving 8.818 oz.
    readonly property var unitData: [
        { key: "pcs", label: AmountFormat.unitLabel("pcs"), step: 1, kind: "", factor: 1, initial: 1 },
        { key: "g", label: AmountFormat.unitLabel("g"), step: 50, kind: "mass", factor: 1, initial: 250 },
        { key: "kg", label: AmountFormat.unitLabel("kg"), step: 0.25, kind: "mass", factor: 1000, initial: 1 },
        { key: "ml", label: AmountFormat.unitLabel("ml"), step: 50, kind: "volume", factor: 1, initial: 250 },
        { key: "cl", label: AmountFormat.unitLabel("cl"), step: 5, kind: "volume", factor: 10, initial: 20 },
        { key: "l", label: AmountFormat.unitLabel("l"), step: 0.25, kind: "volume", factor: 1000, initial: 1 },
        { key: "oz", label: AmountFormat.unitLabel("oz"), step: 1, kind: "usMass", factor: 1, initial: 8 },
        { key: "lb", label: AmountFormat.unitLabel("lb"), step: 0.25, kind: "usMass", factor: 16, initial: 1 },
        { key: "fl_oz", label: AmountFormat.unitLabel("fl_oz"), step: 2, kind: "usVolume", factor: 1, initial: 8 },
        { key: "pack", label: AmountFormat.unitLabel("pack"), step: 1, kind: "", factor: 1, initial: 1 },
        { key: "bunch", label: AmountFormat.unitLabel("bunch"), step: 1, kind: "", factor: 1, initial: 1 }
    ]
    // The item's stored unit while the unit system doesn't offer it (250 g in
    // US), until the user picks another; "" otherwise
    property string extraUnit
    // The unit system's units, then the extra one
    readonly property var units: {
        const keys = Array.from(UnitSettings.unitChoices)
        if (sheet.extraUnit !== "")
            keys.push(sheet.extraUnit)
        return keys.map(key => sheet.unitData.find(u => u.key === key)).filter(u => u !== undefined)
    }

    // The item left the catalog; the caller can offer to undo it
    signal removed(string ingredientId, string name)
    // A change failed (CatalogListModel.Error)
    signal failed(int error)
    // Something to tell the user
    signal message(string text)

    // An aisle to pick, in a two-column grid
    component AisleChoice: ChoiceChip {
        id: choice

        required property string aisleId
        required property string name
        required property color fill
        required property color ink
        required property color darkFill
        required property color darkInk

        readonly property colorFamily family: ({
                                                   fill: sheet.theme.dark ? choice.darkFill : choice.fill,
                                                   ink: sheet.theme.dark ? choice.darkInk : choice.ink
                                               })

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        size: ChoiceChip.Grid
        text: choice.name
        dotColor: choice.family.ink
        checkable: false
        checked: choice.aisleId === sheet.aisleId
        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: choice.checked
        onClicked: sheet.aisleId = choice.aisleId
    }

    // A label above a part of the form
    component PartTitle: Text {
        font: UiTypography.labelLBold
        color: sheet.theme.ink
        elide: Text.ElideRight
        Accessible.role: Accessible.Heading
    }

    function openNew(aisleId: string) {
        sheet.prepare("", "", aisleId, "", 1, "pcs")
    }

    function openItem(ingredientId: string, name: string, aisleId: string, icon: string, quantity: real,
                      unit: string) {
        sheet.prepare(ingredientId, name, aisleId, icon, quantity, unit)
    }

    function prepare(ingredientId: string, name: string, aisleId: string, icon: string, quantity: real,
                  unit: string) {
        sheet.ingredientId = ingredientId
        sheet.originalName = name
        nameField.text = name
        sheet.aisleId = aisleId
        sheet.icon = icon
        sheet.quantity = quantity
        sheet.unit = unit
        sheet.extraUnit = UnitSettings.unitChoices.includes(unit) ? "" : unit
        sheet.addingAisle = false
        aisleForm.name = ""
        form.scrollTo(0)
        sheet.open()
    }

    function chooseUnit(unit: string, amount: real) {
        const from = sheet.unitData.find(u => u.key === sheet.unit)
        const to = sheet.unitData.find(u => u.key === unit)
        // QuantityField converts within a kind and keeps the number across
        // kinds, where 250 g would become 250 pieces
        const sameKind = to.kind !== "" && to.kind === from?.kind
        sheet.unit = unit
        sheet.quantity = sameKind ? amount : to.initial
        sheet.extraUnit = ""
    }

    function save() {
        const error = sheet.editing
                    ? sheet.catalog.update(sheet.ingredientId, nameField.text, sheet.aisleId, sheet.icon,
                                           sheet.quantity, sheet.unit)
                    : sheet.catalog.add(nameField.text, sheet.aisleId, sheet.icon, sheet.quantity, sheet.unit)
        if (error === CatalogListModel.Error.NoError)
            sheet.close()
        else
            sheet.failed(error)
    }

    function remove() {
        const ingredientId = sheet.ingredientId
        const error = sheet.catalog.removeFromCatalog(ingredientId)
        if (error !== CatalogListModel.Error.NoError) {
            sheet.failed(error)
            return
        }
        sheet.close()
        sheet.removed(ingredientId, sheet.originalName)
    }

    function createAisle() {
        const color = AisleColors.all[aisleForm.colorIndex]
        const error = sheet.aisles.create(aisleForm.name, color.fill, color.ink, color.darkFill, color.darkInk)
        if (error !== AisleListModel.Error.NoError) {
            sheet.message(ErrorTexts.aisle(error))
            return
        }
        sheet.aisleId = sheet.aisles.aisleIdAt(sheet.aisles.count - 1)
        aisleForm.name = ""
        sheet.addingAisle = false
    }

    tall: true
    focus: true
    title: sheet.editing ? qsTr("Edit item") : qsTr("New item")

    headerAction: Button {
        variant: Button.Text
        size: Button.Small
        muted: true
        text: qsTr("Cancel")
        onClicked: sheet.close()
    }

    footer: Button {
        variant: Button.Primary
        size: Button.Large
        text: sheet.editing ? qsTr("Save changes") : qsTr("Add to catalog")
        enabled: sheet.nameStatus === CatalogListModel.Error.NoError
        onClicked: sheet.save()
    }

    ScrollArea {
        id: form

        Layout.fillWidth: true
        Layout.fillHeight: true
        contentHeight: parts.implicitHeight
        yieldsAtStart: true
        clip: true

        ColumnLayout {
            id: parts

            width: parent.width
            spacing: UiMetrics.space5

            RowLayout {
                Layout.fillWidth: true
                spacing: UiMetrics.space3

                // Centered on the name's pill, under its label
                IconBadge {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: nameField.topInset + (nameField.pillHeight - height) / 2
                    shape: IconBadge.Tile
                    size: IconBadge.Large
                    iconSource: IngredientIcons.source(sheet.icon)
                    family: sheet.family
                }

                TextField {
                    id: nameField

                    readonly property bool taken: sheet.nameStatus === CatalogListModel.Error.DuplicateName
                                                  || sheet.nameStatus === CatalogListModel.Error.NameTaken

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    label: qsTr("Name")
                    error: nameField.taken
                    helperText: nameField.taken ? ErrorTexts.catalog(sheet.nameStatus) : ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: UiMetrics.space2

                PartTitle {
                    Layout.fillWidth: true
                    text: qsTr("Aisle")
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: UiMetrics.space2
                    rowSpacing: UiMetrics.space2

                    Repeater {
                        id: aisleChoices

                        model: sheet.aisles

                        delegate: AisleChoice {}
                    }

                    ChoiceChip {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        size: ChoiceChip.Grid
                        add: true
                        text: qsTr("New aisle")
                        onClicked: sheet.addingAisle = true
                    }
                }

                AisleForm {
                    id: aisleForm

                    visible: sheet.addingAisle
                    Layout.fillWidth: true
                    placeholderText: qsTr("Aisle name, e.g. Frozen")
                    colors: AisleColors.choices(sheet.theme)
                    onAddClicked: sheet.createAisle()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: UiMetrics.space2

                PartTitle {
                    Layout.fillWidth: true
                    text: qsTr("Icon")
                }

                IngredientIconGrid {
                    Layout.fillWidth: true
                    currentIcon: sheet.icon
                    family: sheet.family
                    // Picking the current icon again leaves the item without one
                    onIconClicked: name => sheet.icon = name === sheet.icon ? "" : name
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: UiMetrics.space2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: UiMetrics.space3

                    PartTitle {
                        Layout.fillWidth: true
                        text: qsTr("One tap adds")
                    }

                    Text {
                        text: AmountFormat.amount(sheet.quantity, sheet.unit)
                        font: UiTypography.qty
                        color: sheet.theme.accent
                    }
                }

                QuantityField {
                    Layout.fillWidth: true
                    header: false
                    units: sheet.units
                    unit: sheet.unit
                    amount: sheet.quantity
                    amountText: AmountFormat.number(sheet.quantity)
                    onAmountEdited: amount => sheet.quantity = amount
                    onUnitEdited: (unit, amount) => sheet.chooseUnit(unit, amount)
                }
            }

            Button {
                visible: sheet.editing
                Layout.alignment: Qt.AlignHCenter
                variant: Button.Text
                destructive: true
                icon.source: CookbookIcons.source("trash")
                text: qsTr("Delete from catalog")
                onClicked: sheet.remove()
            }
        }
    }
}
