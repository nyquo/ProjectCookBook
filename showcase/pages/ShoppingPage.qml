pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating
import CookbookUi

GroupPage {
    id: page

    // In shop order. Rows keep their aisle index and their place in it.
    readonly property var aisles: [
        { name: qsTr("Produce"), family: page.mint, model: produce },
        { name: qsTr("Dairy"), family: page.sky, model: dairy },
        { name: qsTr("Bakery"), family: page.butter, model: bakery },
        { name: qsTr("Dry goods"), family: page.peach, model: dryGoods }
    ]
    // The key of the row about to land, so its delegate animates in
    property string landing
    // What Clear removed, for Undo
    property var cleared: []

    scenes: [
        { name: "moved", show: () => { page.toCart(produce, "garlic"); page.reveal(cartGroup) }, hide: () => {} }
    ]

    function copy(element: var): var {
        return {
            key: element.key,
            name: element.name,
            sources: element.sources,
            quantities: element.quantities,
            icon: element.icon,
            aisle: element.aisle,
            order: element.order
        }
    }

    function indexOf(model: ListModel, key: string): int {
        for (let i = 0; i < model.count; ++i) {
            if (model.get(i).key === key)
                return i
        }
        return -1
    }

    // After a row left its aisle: it lands at the top of the cart
    function toCart(from: ListModel, key: string) {
        const at = page.indexOf(from, key)
        if (at < 0)
            return
        const item = page.copy(from.get(at))
        from.remove(at)
        page.landing = key
        cart.insert(0, item)
    }

    // After a row left the cart: it lands back at its place in its aisle
    function toAisle(key: string) {
        const at = page.indexOf(cart, key)
        if (at < 0)
            return
        const item = page.copy(cart.get(at))
        cart.remove(at)
        const aisle = page.aisles[item.aisle].model
        let place = 0
        while (place < aisle.count && aisle.get(place).order < item.order)
            ++place
        page.landing = key
        aisle.insert(place, item)
    }

    function clearCart() {
        const items = []
        for (let i = 0; i < cart.count; ++i)
            items.push(page.copy(cart.get(i)))
        page.cleared = items
        cart.clear()
        ShowcaseState.notify(items.length === 1 ? qsTr("1 item removed") : qsTr("%1 items removed").arg(items.length),
                             () => {
                                 for (const item of page.cleared)
                                     cart.append(item)
                                 page.cleared = []
                             })
    }

    // A row of a group: collapses and slides down while fading when it leaves,
    // drops in when it lands
    component ShoppingRow: Item {
        id: row

        required property string key
        required property string name
        required property string sources
        required property string quantities
        required property string icon
        required property int aisle
        required property ListModel source
        required property Group group

        property real reveal: 1
        property real shift: 0

        implicitHeight: item.implicitHeight * row.reveal
        clip: true

        function leave() {
            row.group.leaving++
            leaving.start()
        }

        ShoppingItem {
            id: item

            y: row.shift
            width: parent.width
            text: row.name
            sources: row.sources
            quantities: row.quantities.split("|")
            ingredientIcon: row.icon
            family: page.aisles[row.aisle].family
            checked: row.group?.cart ?? false
            onToggled: row.leave()
            onLongPressed: itemMenu.openUnder(item)
        }

        SequentialAnimation {
            id: leaving

            ParallelAnimation {
                NumberAnimation {
                    target: row
                    property: "reveal"
                    to: 0
                    duration: UiMotion.move(UiMotion.listLeave)
                    easing.type: Easing.Bezier
                    easing.bezierCurve: UiMotion.decelerate
                }
                NumberAnimation {
                    target: row
                    property: "shift"
                    to: UiMotion.reduced ? 0 : UiMetrics.space4
                    duration: UiMotion.move(UiMotion.listLeave)
                }
                NumberAnimation {
                    target: item
                    property: "opacity"
                    to: 0
                    duration: UiMotion.fade(UiMotion.listLeave)
                }
            }
            ScriptAction {
                script: {
                    row.group.leaving--
                    if (row.group.cart)
                        page.toAisle(row.key)
                    else
                        page.toCart(row.source, row.key)
                }
            }
        }

        ParallelAnimation {
            id: landing

            NumberAnimation {
                target: row
                property: "reveal"
                from: 0
                to: 1
                duration: UiMotion.move(UiMotion.listLand)
                easing.type: Easing.Bezier
                easing.bezierCurve: UiMotion.decelerate
            }
            NumberAnimation {
                target: row
                property: "shift"
                from: UiMotion.reduced ? 0 : -UiMetrics.space4
                to: 0
                duration: UiMotion.move(UiMotion.listLand)
                easing.type: Easing.Bezier
                easing.bezierCurve: UiMotion.decelerate
            }
            NumberAnimation {
                target: item
                property: "opacity"
                from: 0
                to: 1
                duration: UiMotion.fade(UiMotion.listLand)
            }
        }

        Component.onCompleted: {
            if (page.landing === row.key) {
                page.landing = ""
                row.reveal = 0
                landing.start()
            }
        }
    }

    // An aisle, or the cart: its header and its card. It folds away while its
    // last row leaves, and unfolds as its first row lands.
    component Group: Item {
        id: aisleGroup

        required property string title
        required property ListModel source
        property colorFamily family
        property bool cart: false
        // Rows on their way out
        property int leaving: 0

        readonly property int shown: aisleGroup.source.count - aisleGroup.leaving
        property real reveal: aisleGroup.shown > 0 ? 1 : 0

        Layout.fillWidth: true
        implicitHeight: content.implicitHeight * aisleGroup.reveal
        clip: true
        opacity: aisleGroup.reveal

        Behavior on reveal {
            NumberAnimation {
                duration: UiMotion.move(aisleGroup.shown > 0 ? UiMotion.listLand : UiMotion.listLeave)
                easing.type: Easing.Bezier
                easing.bezierCurve: UiMotion.decelerate
            }
        }

        ColumnLayout {
            id: content

            width: parent.width
            spacing: 0

            SectionHeader {
                Layout.fillWidth: true
                size: aisleGroup.cart ? SectionHeader.Large : SectionHeader.Default
                text: aisleGroup.title
                count: `${aisleGroup.shown}`
                dotColor: aisleGroup.cart ? "transparent" : aisleGroup.family.ink
                actionText: aisleGroup.cart ? qsTr("Clear") : ""
                onActionClicked: page.clearCart()
            }

            ListGroup {
                Layout.fillWidth: true
                Layout.bottomMargin: CookbookMetrics.shoppingGroupGap
                iconRows: true

                Repeater {
                    model: aisleGroup.source

                    delegate: ShoppingRow {
                        source: aisleGroup.source
                        group: aisleGroup
                    }
                }
            }
        }
    }

    title: qsTr("Shopping")
    subtitle: qsTr("ShoppingItem, IngredientTile")

    Specimen {
        title: qsTr("ShoppingItem, grouped by aisle")
        note: qsTr("Tap an item: it moves to the cart, and back. Press and hold for its menu.")

        ColumnLayout {
            width: parent.width
            spacing: 0

            Repeater {
                model: page.aisles

                delegate: Group {
                    required property var modelData

                    title: modelData.name
                    family: modelData.family
                    source: modelData.model
                }
            }

            Group {
                id: cartGroup

                title: qsTr("In the cart")
                source: cart
                cart: true
            }
        }
    }

    Specimen {
        title: qsTr("ShoppingItem: pressed, disabled")

        ListGroup {
            width: parent.width
            iconRows: true

            ShoppingItem {
                down: true
                text: qsTr("Pressed")
                sources: qsTr("Added by you")
                quantities: [qsTr("1 pack")]
                family: page.butter
            }
            ShoppingItem {
                enabled: false
                text: qsTr("Disabled")
                quantities: [qsTr("2 pcs")]
                family: page.sky
            }
        }
    }

    Specimen {
        title: qsTr("IngredientTile: available, on the list, needed by a recipe")
        note: qsTr("Tap an available tile to add it; the stepper counts, and removes at 1.")

        GridLayout {
            width: parent.width
            columns: 2
            columnSpacing: UiMetrics.space2
            rowSpacing: UiMetrics.space2

            Repeater {
                model: tiles

                delegate: IngredientTile {
                    id: tile

                    required property int index
                    required property string label
                    required property string iconKey
                    required property int aisleIndex
                    required property string defaultAmount
                    required property int stage
                    required property real qty
                    required property real step
                    required property string unit
                    required property string why

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    text: tile.label
                    ingredientIcon: tile.iconKey
                    family: page.aisles[tile.aisleIndex].family
                    status: tile.stage
                    amount: tile.defaultAmount
                    neededText: tile.why
                    quantity: `${tile.qty.toLocaleString(Qt.locale(), "f", tile.step < 1 ? 1 : 0)} ${tile.unit}`
                    canDecrease: tile.qty > tile.step
                    onAddClicked: tiles.setProperty(tile.index, "stage", IngredientTile.OnList)
                    onIncreaseClicked: tiles.setProperty(tile.index, "qty", tile.qty + tile.step)
                    onDecreaseClicked: tiles.setProperty(tile.index, "qty", tile.qty - tile.step)
                    onRemoveClicked: tiles.setProperty(tile.index, "stage", IngredientTile.Available)
                }
            }
        }
    }

    ListModel {
        id: produce

        ListElement {
            key: "potatoes"
            name: qsTr("Potatoes")
            sources: qsTr("Gratin")
            quantities: qsTr("1,2 kg")
            icon: "potato"
            aisle: 0
            order: 0
        }
        ListElement {
            key: "leeks"
            name: qsTr("Leeks")
            sources: qsTr("Tarte aux poireaux")
            quantities: qsTr("3 pcs")
            icon: "leek"
            aisle: 0
            order: 1
        }
        ListElement {
            key: "garlic"
            name: qsTr("Garlic")
            sources: qsTr("Gratin, Dahl")
            quantities: qsTr("2 cloves|1 head")
            icon: "garlic"
            aisle: 0
            order: 2
        }
        ListElement {
            key: "ginger"
            name: qsTr("Ginger")
            sources: qsTr("Dahl")
            quantities: qsTr("30 g")
            icon: "ginger"
            aisle: 0
            order: 3
        }
    }

    ListModel {
        id: dairy

        ListElement {
            key: "milk"
            name: qsTr("Whole milk")
            sources: qsTr("Gratin")
            quantities: qsTr("50 cl")
            icon: "milk"
            aisle: 1
            order: 0
        }
        ListElement {
            key: "cream"
            name: qsTr("Cream")
            sources: qsTr("Gratin")
            quantities: qsTr("20 cl")
            icon: "cream"
            aisle: 1
            order: 1
        }
        ListElement {
            key: "butter"
            name: qsTr("Butter")
            sources: qsTr("Added by you")
            quantities: qsTr("250 g")
            icon: "butter"
            aisle: 1
            order: 2
        }
    }

    ListModel {
        id: bakery

        ListElement {
            key: "baguette"
            name: qsTr("Baguette")
            sources: qsTr("Added by you")
            quantities: qsTr("2 pcs")
            icon: "bread"
            aisle: 2
            order: 0
        }
    }

    ListModel {
        id: dryGoods

        ListElement {
            key: "lentils"
            name: qsTr("Red lentils")
            sources: qsTr("Dahl")
            quantities: qsTr("300 g")
            icon: "lentils"
            aisle: 3
            order: 0
        }
    }

    ListModel {
        id: cart

        ListElement {
            key: "coconut"
            name: qsTr("Coconut milk")
            sources: qsTr("Dahl")
            quantities: qsTr("40 cl")
            icon: "coconut"
            aisle: 3
            order: 1
        }
    }

    ListModel {
        id: tiles

        ListElement {
            label: qsTr("Onions")
            iconKey: "onion"
            aisleIndex: 0
            defaultAmount: qsTr("1 kg")
            stage: 0
            qty: 1
            step: 0.5
            unit: qsTr("kg")
            why: ""
        }
        ListElement {
            label: qsTr("Eggs")
            iconKey: "egg"
            aisleIndex: 1
            defaultAmount: qsTr("6 pcs")
            stage: 1
            qty: 6
            step: 1
            unit: qsTr("pcs")
            why: ""
        }
        ListElement {
            label: qsTr("Red lentils")
            iconKey: "lentils"
            aisleIndex: 3
            defaultAmount: qsTr("500 g")
            stage: 2
            qty: 500
            step: 50
            unit: qsTr("g")
            why: qsTr("On your list, for Dahl")
        }
        ListElement {
            label: qsTr("Butter")
            iconKey: "butter"
            aisleIndex: 1
            defaultAmount: qsTr("250 g")
            stage: 0
            qty: 250
            step: 50
            unit: qsTr("g")
            why: ""
        }
    }

    Menu {
        id: itemMenu

        MenuItem {
            icon.name: "edit"
            text: qsTr("Edit quantity")
        }
        MenuItem {
            icon.name: "link"
            text: qsTr("Show the recipes")
        }
        MenuSeparator {}
        MenuItem {
            icon.name: "trash"
            destructive: true
            text: qsTr("Remove from the list")
        }
    }
}
