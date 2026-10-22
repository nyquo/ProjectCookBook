pragma Singleton

import QtQuick

// Spacing, radii, sizes and shadow geometry, in design px passed through
// UiScaler
QtObject {
    // Icon to text in small pills; gaps inside the stepper
    readonly property real space1: UiScaler.scale(4)
    // Between chips and between tag pills
    readonly property real space2: UiScaler.scale(8)
    // Between a thumbnail and its text; between cards in a stack
    readonly property real space3: UiScaler.scale(12)
    // Screen side margins; card and step-card padding
    readonly property real space4: UiScaler.scale(16)
    // Between sections of the recipe screen
    readonly property real space5: UiScaler.scale(20)
    // Top padding of screens and of the sheet over the photo
    readonly property real space6: UiScaler.scale(24)
    // Large separations; bottom clearance above floating actions
    readonly property real space8: UiScaler.scale(32)

    // Small overlays on images (favorite toggle on a card)
    readonly property real radiusSm: UiScaler.scale(14)
    // Thumbnails, step cards, the notes card
    readonly property real radiusMd: UiScaler.scale(20)
    // Content cards: ingredients card, spec strip
    readonly property real radiusLg: UiScaler.scale(28)
    // Top corners of the sheet over the recipe photo, and of bottom sheets
    readonly property real radiusSheet: UiScaler.scale(32)
    // Every control: buttons, chips, search field, pills, round buttons
    // Rectangle clamps it to half the smaller side
    readonly property real radiusPill: UiScaler.scale(999)

    // Minimum touch target: chips, stepper buttons, small round buttons
    readonly property real sizeTouch: UiScaler.scale(44)
    // Search field; round buttons over a photo
    readonly property real sizeControl: UiScaler.scale(52)
    // What a round button over a photo draws inside its sizeControl area
    readonly property real sizeControlVisual: UiScaler.scale(48)
    // New recipe button and bottom action buttons
    readonly property real sizeCta: UiScaler.scale(60)
    // Recipe thumbnails in the list
    readonly property real sizeThumb: UiScaler.scale(62)
    // Default icon size (18 to 20 px inside chips and pills)
    readonly property real sizeIcon: UiScaler.scale(22)

    // Keyboard focus ring: a solid line, drawn this far outside the control
    readonly property real focusRingWidth: UiScaler.scale(2)
    readonly property real focusRingOffset: UiScaler.scale(2)

    readonly property real shadowRaisedOffsetY: UiScaler.scale(10)
    readonly property real shadowRaisedBlur: UiScaler.scale(24)

    // Separators. Not scaled: a hairline stays one pixel
    readonly property real hairline: 1
}
