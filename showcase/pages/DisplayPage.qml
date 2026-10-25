import QtQuick
import Plating
import CookbookUi

GroupPage {
    id: page

    readonly property url photo: Qt.resolvedUrl("../images/gratin.svg")

    title: qsTr("Display")
    subtitle: qsTr("TagPill, IconBadge, Thumbnail, SpecStrip, SplitBar")

    Specimen {
        title: qsTr("TagPill: default and large")

        TagPill {
            text: qsTr("Vegetarian")
            family: page.mint
        }
        TagPill {
            text: qsTr("Side")
            family: page.butter
        }
        TagPill {
            text: qsTr("Weeknight")
            family: page.sky
        }
        TagPill {
            text: qsTr("Oven")
            family: page.peach
        }
        TagPill {
            size: TagPill.Large
            text: qsTr("Vegetarian")
            family: page.mint
        }
        TagPill {
            size: TagPill.Large
            text: qsTr("Sunday")
            family: page.butter
        }
    }

    Specimen {
        title: qsTr("IconBadge: discs 30, 36, 40, 44; muted")
        note: qsTr("Ingredient icons fall back to the jar until their files are added.")

        IconBadge {
            size: IconBadge.ExtraSmall
            iconSource: IngredientIcons.source("lemon")
            family: page.butter
        }
        IconBadge {
            size: IconBadge.Small
            iconSource: IngredientIcons.source("carrot")
            family: page.peach
        }
        IconBadge {
            iconSource: IngredientIcons.source("leek")
            family: page.mint
        }
        IconBadge {
            size: IconBadge.Large
            iconName: "basket"
            family: page.sky
        }
        IconBadge {
            size: IconBadge.Large
            iconSource: IngredientIcons.source("milk")
            muted: true
        }
    }

    Specimen {
        title: qsTr("IconBadge: tiles 40, 56, 64")

        IconBadge {
            shape: IconBadge.Tile
            size: IconBadge.Small
            iconSource: IngredientIcons.source("potato")
            family: page.butter
        }
        IconBadge {
            shape: IconBadge.Tile
            size: IconBadge.Medium
            iconName: "book"
            family: page.mint
        }
        IconBadge {
            shape: IconBadge.Tile
            size: IconBadge.Large
            iconName: "calendar"
            family: page.sky
        }
    }

    Specimen {
        title: qsTr("Thumbnail: picture, initials, small")

        Thumbnail {
            source: page.photo
            initials: "GD"
            family: page.butter
        }
        Thumbnail {
            initials: "DL"
            family: page.peach
        }
        Thumbnail {
            initials: "TP"
            family: page.mint
        }
        Thumbnail {
            size: Thumbnail.Small
            source: page.photo
            initials: "GD"
            family: page.butter
        }
        Thumbnail {
            size: Thumbnail.Small
            initials: "Sb"
            family: page.sky
        }
    }

    Specimen {
        title: qsTr("SpecStrip")
        note: qsTr("The last value is missing.")

        SpecStrip {
            width: parent.width
            model: [
                { label: qsTr("Prep"), value: qsTr("25 min"), detail: "" },
                { label: qsTr("Cook"), value: qsTr("1 h 15"), detail: qsTr("at 160 °C") },
                { label: qsTr("Serves"), value: "6", detail: "" },
                { label: qsTr("Cost"), value: "", detail: "" }
            ]
        }
    }

    Specimen {
        title: qsTr("SplitBar: a 1 kg bag of red lentils")

        SplitBar {
            width: parent.width
            total: 1000
            parts: [
                { label: qsTr("Dahl de lentilles corail (this recipe)"), value: qsTr("400 g"), amount: 400, current: true },
                { label: qsTr("Lentil soup"), value: qsTr("300 g"), amount: 300, current: false }
            ]
        }
    }
}
