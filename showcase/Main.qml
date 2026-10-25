pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Plating

ApplicationWindow {
    id: window

    readonly property list<PageEntry> pages: [
        PageEntry {
            slug: "actions"
            title: qsTr("Actions")
            summary: qsTr("Button, IconButton, floating action button")
            page: Component {
                ActionsPage {}
            }
        },
        PageEntry {
            slug: "structure"
            title: qsTr("Structure")
            summary: qsTr("ScreenHeader, SectionHeader, ListGroup and ListRow")
            page: Component {
                StructurePage {}
            }
        },
        PageEntry {
            slug: "inputs"
            title: qsTr("Inputs")
            summary: qsTr("Text fields, ComboBox, CheckBox, Switch, SegmentedControl, Stepper, chips, ColorSwatch")
            page: Component {
                InputsPage {}
            }
        },
        PageEntry {
            slug: "display"
            title: qsTr("Display")
            summary: qsTr("TagPill, IconBadge, Thumbnail, SpecStrip, SplitBar")
            page: Component {
                DisplayPage {}
            }
        },
        PageEntry {
            slug: "overlays"
            title: qsTr("Navigation and overlays")
            summary: qsTr("BottomNav, BottomSheet, Menu, Snackbar, EmptyState")
            page: Component {
                OverlaysPage {}
            }
        },
        PageEntry {
            slug: "quantities"
            app: true
            title: qsTr("Quantities")
            summary: qsTr("QuantityPill, QuantityField")
            page: Component {
                QuantitiesPage {}
            }
        },
        PageEntry {
            slug: "recipes"
            app: true
            title: qsTr("Recipes")
            summary: qsTr("RecipeHeader, RecipeRow, PlannedRecipeCard, SortMenu, NoteCard")
            page: Component {
                RecipesPage {}
            }
        },
        PageEntry {
            slug: "ingredients"
            app: true
            title: qsTr("Ingredients and steps")
            summary: qsTr("IngredientRow, StepCard")
            page: Component {
                IngredientsPage {}
            }
        },
        PageEntry {
            slug: "shopping"
            app: true
            title: qsTr("Shopping")
            summary: qsTr("ShoppingItem, IngredientTile")
            page: Component {
                ShoppingPage {}
            }
        }
    ]

    // Phone-sized on desktop; ignored on Android (always fullscreen)
    width: 390
    height: 844
    visible: true
    title: qsTr("Showcase")

    // Edge to edge: on Android the window goes under the status and navigation
    // bars, and each screen pads itself with SafeArea.
    flags: Qt.platform.os === "android" ? Qt.Window | Qt.ExpandedClientAreaHint : Qt.Window
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    Plating.theme: ShowcaseState.dark ? DefaultDarkTheme : DefaultLightTheme

    Binding {
        target: DefaultLightTheme
        property: "accentChoice"
        value: ShowcaseState.accent
    }
    Binding {
        target: DefaultDarkTheme
        property: "accentChoice"
        value: ShowcaseState.accent
    }
    Binding {
        target: UiMotion
        property: "reduced"
        value: ShowcaseState.reducedMotion
    }
    // Also gives the status bar icons the right contrast on Android
    Binding {
        target: Application.styleHints
        property: "colorScheme"
        value: ShowcaseState.dark ? Qt.ColorScheme.Dark : Qt.ColorScheme.Light
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ShowcaseBar {
            Layout.fillWidth: true
        }

        StackView {
            id: stack

            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: home

            pushEnter: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: UiMotion.fade(UiMotion.pageEnter)
                }
                NumberAnimation {
                    property: "y"
                    from: UiMotion.reduced ? 0 : UiMetrics.pageEnterOffset
                    to: 0
                    duration: UiMotion.move(UiMotion.pageEnter)
                    easing.type: Easing.Bezier
                    easing.bezierCurve: UiMotion.decelerate
                }
            }
            pushExit: Transition {
                NumberAnimation {
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: UiMotion.fade(UiMotion.pageEnter)
                }
            }
            popEnter: stack.pushEnter
            popExit: stack.pushExit
            replaceEnter: stack.pushEnter
            replaceExit: stack.pushExit
        }
    }

    // The window's only snackbar; pages show it with ShowcaseState.notify()
    Snackbar {
        id: snackbar

        onActionClicked: ShowcaseState.runAction()
        Component.onCompleted: ShowcaseState.snackbar = snackbar
    }

    HomePage {
        id: home

        pages: window.pages
        onOpened: entry => stack.push(entry.page)
    }

    // --capture <folder>: saves each page in both themes, then quits
    QtObject {
        id: capture

        property string folder
        property list<string> queue

        function start(folder: string) {
            capture.folder = folder
            for (const dark of [false, true]) {
                const theme = dark ? "dark" : "light"
                capture.queue.push(`${theme}:screen`)
                capture.queue.push(`${theme}:home`)
                for (const entry of window.pages)
                    capture.queue.push(`${theme}:${entry.slug}`)
            }
            capture.next()
        }

        function next() {
            if (capture.queue.length === 0) {
                Qt.quit()
                return
            }
            const [theme, slug] = capture.queue[0].split(":")
            ShowcaseState.dark = theme === "dark"
            stack.pop(null, StackView.Immediate)
            const entry = window.pages.find(page => page.slug === slug)
            if (entry)
                stack.push(entry.page, {}, StackView.Immediate)
            settle.restart()
        }

        // The page at full height, then its scenes as window captures
        function save() {
            const [theme, slug] = capture.queue.shift().split(":")
            capture.theme = theme
            capture.slug = slug
            if (slug === "screen") {
                WindowCapture.save(window, `${capture.folder}/${slug}-${theme}.png`)
                capture.next()
                return
            }
            const page = stack.currentItem as GroupPage
            const item = page ? page.captureItem : home.captureItem
            const grabbing = item.grabToImage(result => {
                result.saveToFile(`${capture.folder}/${slug}-${theme}.png`)
                capture.scenes = page ? page.scenes : []
                capture.sceneIndex = -1
                capture.nextScene()
            })
            if (!grabbing) {
                console.warn(`Can't capture ${slug}`)
                capture.next()
            }
        }

        property string theme
        property string slug
        property var scenes: []
        property int sceneIndex: -1

        function nextScene() {
            capture.sceneIndex++
            if (capture.sceneIndex >= capture.scenes.length) {
                capture.next()
                return
            }
            capture.scenes[capture.sceneIndex].show()
            sceneShown.restart()
        }
    }

    // Lets the page lay out and load before it's grabbed
    Timer {
        id: settle

        interval: 300
        onTriggered: capture.save()
    }

    // Lets a scene's animations finish before the window is grabbed
    Timer {
        id: sceneShown

        interval: 900
        onTriggered: {
            const scene = capture.scenes[capture.sceneIndex]
            WindowCapture.save(window, `${capture.folder}/${capture.slug}-${scene.name}-${capture.theme}.png`)
            scene.hide()
            sceneHidden.restart()
        }
    }

    Timer {
        id: sceneHidden

        interval: 500
        onTriggered: capture.nextScene()
    }

    Component.onCompleted: {
        const args = Qt.application.arguments
        const at = args.indexOf("--capture")
        if (at >= 0 && at + 1 < args.length)
            capture.start(args[at + 1])
    }
}
