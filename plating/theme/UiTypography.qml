pragma Singleton

import QtQuick

// Text styles. The design's named styles come first (titleXL … tag); the
// others complete them by size, named after the style of that size and the
// weight: labelBold is label (15/600) at 700. Only styles that wrap have a line
// height; the others sit on one line.
QtObject {
    id: root

    readonly property FontLoader fontLoader: FontLoader {
        source: "qrc:/qt/qml/Plating/fonts/BricolageGrotesque-Variable.ttf"
    }
    readonly property string family: root.fontLoader.name

    // Screen titles (Recipes) and the recipe name
    readonly property font titleXL: root.makeFont(36, 800, -0.03)
    readonly property real titleXLLineHeight: root.lineHeight(root.titleXL, 1.02)
    // Section headers inside a screen: Ingredients, Steps
    readonly property font titleL: root.makeFont(22, 800, -0.02)
    readonly property real titleLLineHeight: root.lineHeight(root.titleL, 1.2)
    // Recipe names in list rows, card titles
    readonly property font titleM: root.makeFont(16, 700, -0.01)
    readonly property real titleMLineHeight: root.lineHeight(root.titleM, 1.2)
    // Editor header titles
    readonly property font titleS: root.makeFont(18, 800, -0.01)
    readonly property real titleSLineHeight: root.lineHeight(root.titleS, 1.2)
    // Big field value (TitleField)
    readonly property font fieldTitle: root.makeFont(34, 800, -0.03)
    // Bottom sheet titles
    readonly property font sheetTitle: root.makeFont(24, 800, -0.02)
    readonly property real sheetTitleLineHeight: root.lineHeight(root.sheetTitle, 1.2)
    // Empty state titles
    readonly property font emptyTitle: root.makeFont(26, 800, -0.02)
    readonly property real emptyTitleLineHeight: root.lineHeight(root.emptyTitle, 1.2)
    // The number of a large stepper
    readonly property font stepperValueL: root.makeFont(52, 800, -0.04)

    // Step text, recipe description, notes. The app's default font
    readonly property font bodyL: root.makeFont(16, 400, 0)
    readonly property real bodyLLineHeight: root.lineHeight(root.bodyL, 1.5)
    // Ingredient words mentioned in a step's text
    readonly property font bodyLStrong: root.makeFont(16, 650, 0)
    readonly property real bodyLStrongLineHeight: root.lineHeight(root.bodyLStrong, 1.5)
    // Sheet subtitles
    readonly property font bodyM: root.makeFont(15, 400, 0)
    readonly property real bodyMLineHeight: root.lineHeight(root.bodyM, 1.35)
    // Header subtitles, trailing values in rows
    readonly property font bodyS: root.makeFont(14, 500, 0)
    readonly property real bodySLineHeight: root.lineHeight(root.bodyS, 1.35)

    // Buttons, chips, ingredient names
    readonly property font label: root.makeFont(15, 600, 0)
    readonly property real labelLineHeight: root.lineHeight(root.label, 1.2)
    readonly property font labelBold: root.makeFont(15, 700, 0)
    readonly property font labelExtraBold: root.makeFont(15, 800, 0)
    // label at 16 px
    readonly property font labelL: root.makeFont(16, 600, 0)
    readonly property real labelLLineHeight: root.lineHeight(root.labelL, 1.2)
    readonly property font labelLBold: root.makeFont(16, 700, 0)
    readonly property font labelLExtraBold: root.makeFont(16, 800, 0)
    // label at 14 px; at 800 it's qty
    readonly property font labelS: root.makeFont(14, 600, 0)
    readonly property font labelSBold: root.makeFont(14, 700, 0)

    // Meta lines: time cooked, counts, sources
    readonly property font caption: root.makeFont(13, 500, 0)
    readonly property real captionLineHeight: root.lineHeight(root.caption, 1.35)
    readonly property font captionSemiBold: root.makeFont(13, 600, 0)
    readonly property font captionBold: root.makeFont(13, 700, 0)
    readonly property font captionExtraBold: root.makeFont(13, 800, 0)
    // Spec-strip labels and nav labels. Sentence case, never all caps
    readonly property font overline: root.makeFont(12, 600, 0)
    readonly property real overlineLineHeight: root.lineHeight(root.overline, 1.3)
    readonly property font overlineMedium: root.makeFont(12, 500, 0)
    // Unit labels under a number
    readonly property font micro: root.makeFont(11, 600, 0)
    readonly property font microMedium: root.makeFont(11, 500, 0)

    // Spec-strip values
    readonly property font value: root.makeFont(17, 800, -0.01)
    readonly property real valueLineHeight: root.lineHeight(root.value, 1.2)
    readonly property font valueBold: root.makeFont(17, 700, -0.01)
    readonly property font valueSemiBold: root.makeFont(17, 600, -0.01)
    // Quantity pills
    readonly property font qty: root.makeFont(14, 800, 0)
    readonly property real qtyLineHeight: root.lineHeight(root.qty, 1)
    // A thumbnail's initials when it has no image; initialsS on a small one
    readonly property font initials: root.makeFont(24, 800, -0.03)
    readonly property real initialsLineHeight: root.lineHeight(root.initials, 1)
    readonly property font initialsS: root.makeFont(16, 800, -0.03)
    // Tag pills in lists
    readonly property font tag: root.makeFont(12, 700, 0)
    readonly property real tagLineHeight: root.lineHeight(root.tag, 1.3)
    // Tag pills in the recipe header
    readonly property font tagL: root.makeFont(13, 700, 0)
    readonly property real tagLLineHeight: root.lineHeight(root.tagL, 1.3)

    // designPixelSize is in design px, before UiScaler; letterSpacingEm is a
    // multiple of the font size.
    function makeFont(designPixelSize: real, weight: int, letterSpacingEm: real): font {
        // Qt fonts take whole pixels
        const pixelSize = Math.round(UiScaler.scale(designPixelSize))
        return Qt.font({
            family: root.family,
            pixelSize: pixelSize,
            weight: weight,
            letterSpacing: letterSpacingEm * pixelSize,
            // Qt sets neither axis by itself. Without opsz, every size would use
            // the 14 pt optical size of the font's named instances, where
            // browsers use the px size; without wght, 650 would snap to a named
            // weight. The font's opsz axis spans 12 to 96.
            variableAxes: {
                wght: weight,
                opsz: Math.min(Math.max(pixelSize, 12), 96)
            }
        })
    }

    function lineHeight(style: font, multiple: real): real {
        return style.pixelSize * multiple
    }

    // The style with tabular figures, for numbers that align in a column. A
    // Text can't take both `font:` and `font.features:`.
    function tabular(style: font): font {
        return root.derive(style, { tnum: 1 }, false)
    }

    // The style struck through
    function strikeout(style: font): font {
        return root.derive(style, style.features, true)
    }

    function derive(style: font, features: var, strikeout: bool): font {
        return Qt.font({
            family: style.family,
            pixelSize: style.pixelSize,
            weight: style.weight,
            letterSpacing: style.letterSpacing,
            variableAxes: style.variableAxes,
            features: features,
            strikeout: strikeout
        })
    }
}
