pragma Singleton

import QtQuick

// Spacing, radii, sizes and shadow geometry, in design px passed through
// UiScaler, then opacities. The scale comes first; component geometry follows,
// grouped by component, and reuses the scale where the values match.
QtObject {
    id: root

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
    // Large round buttons: header actions, buttons over a photo
    readonly property real sizeControlVisual: UiScaler.scale(48)
    // New recipe button and bottom action buttons
    readonly property real sizeCta: UiScaler.scale(60)
    // Recipe thumbnails in the list
    readonly property real sizeThumb: UiScaler.scale(62)
    // Default icon size (18 to 20 px inside chips and pills)
    readonly property real sizeIcon: UiScaler.scale(22)
    readonly property real iconXS: UiScaler.scale(14)
    readonly property real iconS: UiScaler.scale(16)
    readonly property real iconM: UiScaler.scale(18)
    readonly property real iconL: UiScaler.scale(20)
    // Icon strokes, in screen px whatever the icon's size
    readonly property real iconStroke: UiScaler.scale(2.2)
    // Stepper − and +, the floating action button's +
    readonly property real iconStrokeEmphasis: UiScaler.scale(2.4)
    // A check mark on a filled disc
    readonly property real iconStrokeCheck: UiScaler.scale(3)
    readonly property real iconStrokeSwatchCheck: UiScaler.scale(2.6)
    // The × of a removable chip
    readonly property real iconStrokeChipClose: UiScaler.scale(2.8)
    // Glyphs made of dots (more, drag), the single dot, the settings gear
    readonly property real iconStrokeDots: UiScaler.scale(3.2)
    readonly property real iconStrokeDot: UiScaler.scale(4)
    readonly property real iconStrokeSettings: UiScaler.scale(2)

    // Keyboard focus ring: a solid line, drawn this far outside the control
    readonly property real focusRingWidth: UiScaler.scale(2)
    readonly property real focusRingOffset: UiScaler.scale(2)
    // Outlines: dashed and outlined controls, the stepper at its minimum
    readonly property real borderThin: UiScaler.scale(1.5)
    // Selection rings, focused and invalid text inputs
    readonly property real borderStrong: UiScaler.scale(2)
    readonly property real dashLength: UiScaler.scale(4)
    readonly property real dashGap: UiScaler.scale(3)

    readonly property real shadowRaisedOffsetY: UiScaler.scale(10)
    readonly property real shadowRaisedBlur: UiScaler.scale(24)
    readonly property real shadowMenuOffsetY: UiScaler.scale(16)
    readonly property real shadowMenuBlur: UiScaler.scale(40)

    // A page entering rises this far while it fades in
    readonly property real pageEnterOffset: root.space2

    // Separators. Not scaled: a hairline stays one pixel
    readonly property real hairline: 1

    // Opacities, not scaled. A disabled control, unless it has its own look
    readonly property real opacityDisabled: 0.4
    // A used list row; secondary text on an ink fill
    readonly property real opacitySecondary: 0.75
    // Something shown but not available; secondary text on a selected segment
    readonly property real opacityMuted: 0.8
    // An IconBadge's icon, as a share of the badge's size
    readonly property real badgeIconRatio: 0.55
    // ScrollArea's position indicator, while shown
    readonly property real opacityScrollIndicator: 0.5

    // ScrollArea: one wheel notch; the position indicator's thickness, its
    // distance to the edges, its shortest length
    readonly property real scrollWheelStep: UiScaler.scale(48)
    readonly property real scrollIndicatorThickness: root.space1
    readonly property real scrollIndicatorMargin: UiScaler.scale(3)
    readonly property real scrollIndicatorMinLength: root.space8

    // Button, per size: height, side padding, padding on the icon side, icon
    // size, icon-to-label gap
    readonly property real buttonHeightL: root.sizeCta
    readonly property real buttonHeightM: root.sizeControl
    readonly property real buttonHeightS: root.sizeTouch
    readonly property real buttonHeightXS: UiScaler.scale(36)
    readonly property real buttonPaddingL: UiScaler.scale(22)
    readonly property real buttonPaddingM: root.space5
    readonly property real buttonPaddingS: UiScaler.scale(18)
    readonly property real buttonPaddingXS: root.space3
    readonly property real buttonIconPaddingL: root.space4
    readonly property real buttonIconPaddingM: root.space4
    readonly property real buttonIconPaddingS: UiScaler.scale(14)
    readonly property real buttonIconPaddingXS: root.space2
    readonly property real buttonIconL: root.sizeIcon
    readonly property real buttonIcon: root.iconL
    readonly property real buttonIconXS: root.iconM
    readonly property real buttonIconGap: root.space2
    readonly property real buttonIconGapXS: root.space1

    // IconButton discs; the small one still takes sizeTouch presses
    readonly property real iconButtonSizeS: UiScaler.scale(40)
    readonly property real iconButtonSize: root.sizeTouch
    readonly property real iconButtonSizeL: root.sizeControlVisual

    // Floating action button. Extended: padding on the icon side and the other
    readonly property real fabSize: root.sizeCta
    readonly property real fabIcon: UiScaler.scale(26)
    readonly property real fabPaddingIcon: UiScaler.scale(18)
    readonly property real fabPadding: root.space6

    // ScreenHeader. Side padding is space4, the screen margin
    readonly property real headerTopPadding: root.space6
    readonly property real headerBottomPadding: root.space3
    readonly property real headerPushedTopPadding: root.space4
    readonly property real headerPushedBottomPadding: root.space2
    readonly property real headerEditorHeight: UiScaler.scale(72)
    readonly property real headerEditorTopPadding: root.space3
    readonly property real headerTitleInset: root.space1
    // Pushed: from the back button to the title
    readonly property real headerTitleGap: UiScaler.scale(14)
    readonly property real headerSubtitleGap: root.space1
    // Between the screen's own controls under a top-level title
    readonly property real headerSlotGap: root.space3

    // SectionHeader: inset from the card it labels, gap above that card
    readonly property real sectionHeaderInset: root.space1
    readonly property real sectionHeaderGap: root.space2
    readonly property real sectionHeaderDot: UiScaler.scale(10)

    // ListGroup and ListRow
    readonly property real listGroupPaddingV: root.space1
    readonly property real listGroupPaddingH: root.space4
    readonly property real listGroupIconPaddingH: root.space3
    readonly property real listRowHeight: root.sizeCta
    // With a leading item or a subtitle
    readonly property real listRowHeightTall: UiScaler.scale(64)
    readonly property real listRowPaddingV: root.space2
    readonly property real listRowGap: root.space3
    readonly property real listRowDisc: UiScaler.scale(40)
    // The pressed overlay reaches this far past the row's sides
    readonly property real listRowPressBleed: root.space2
    readonly property real listRowHighlightRadius: UiScaler.scale(24)
    readonly property real listRowHighlightPaddingStart: root.space4
    readonly property real listRowHighlightPaddingEnd: root.space3

    // ColorSwatch: touch target with the selection ring at its edge, and the disc
    readonly property real swatchSize: root.sizeControlVisual
    readonly property real swatchDisc: UiScaler.scale(40)

    // TextField: pill height and side padding, default and compact; leading
    // icon to text; padding right of a trailing button; label and helper gap
    // and inset
    readonly property real textFieldHeight: root.sizeControl
    readonly property real textFieldHeightCompact: root.sizeTouch
    readonly property real textFieldPadding: UiScaler.scale(18)
    readonly property real textFieldPaddingCompact: UiScaler.scale(14)
    readonly property real textFieldIconGap: UiScaler.scale(10)
    readonly property real textFieldActionPadding: UiScaler.scale(6)
    readonly property real textFieldLabelGap: UiScaler.scale(6)
    readonly property real textFieldLabelInset: root.space1
    readonly property real textFieldSuffixGap: root.space1

    // TextArea padding
    readonly property real textAreaPaddingV: UiScaler.scale(14)
    readonly property real textAreaPaddingH: root.space4

    // TitleField: inset, label to value, value to underline
    readonly property real titleFieldInset: root.space1
    readonly property real titleFieldLabelGap: UiScaler.scale(6)
    readonly property real titleFieldUnderlineGap: UiScaler.scale(6)

    // ComboBox: heights, padding before the value and after the chevron, gap
    readonly property real comboBoxHeight: root.sizeTouch
    readonly property real comboBoxHeightMedium: root.sizeControl
    readonly property real comboBoxPaddingStart: UiScaler.scale(14)
    readonly property real comboBoxPaddingEnd: UiScaler.scale(10)
    readonly property real comboBoxIconGap: root.space2

    // Menu, and the ComboBox popup that looks like one
    readonly property real menuMinWidth: UiScaler.scale(288)
    readonly property real menuRadius: UiScaler.scale(24)
    readonly property real menuPadding: root.space2
    // Between the anchor and the menu; the least room left around a menu
    readonly property real menuGap: root.space1
    readonly property real menuMargin: root.space2
    readonly property real menuTitlePaddingTop: root.space2
    readonly property real menuTitlePaddingH: root.space3
    readonly property real menuTitlePaddingBottom: UiScaler.scale(6)
    readonly property real menuItemHeight: root.sizeControl
    readonly property real menuItemRadius: root.space4
    readonly property real menuItemPaddingV: root.space2
    readonly property real menuItemPaddingH: root.space3
    readonly property real menuItemArrowDisc: UiScaler.scale(36)
    readonly property real menuSeparatorMarginV: root.space1
    readonly property real menuSeparatorMarginH: root.space3

    // CheckBox: circle and gap to the label
    readonly property real checkBoxSize: UiScaler.scale(24)
    readonly property real checkBoxGap: UiScaler.scale(10)

    // Switch: track; thumb off and on, and its distance to the track's edge
    readonly property real switchWidth: UiScaler.scale(52)
    readonly property real switchHeight: root.space8
    readonly property real switchThumbOff: root.space4
    readonly property real switchThumbOn: root.space6
    readonly property real switchThumbInsetOff: root.space2
    readonly property real switchThumbInsetOn: root.space1

    // SegmentedControl
    readonly property real segmentHeight: root.sizeTouch
    readonly property real segmentPadding: root.space2
    readonly property real segmentedPadding: root.space1
    readonly property real segmentedGap: root.space1
    readonly property real segmentedGapPlain: root.space2

    // Stepper: capsule padding and gaps; buttons per size; value width
    readonly property real stepperPadding: root.space1
    readonly property real stepperGap: root.space1
    readonly property real stepperGapL: UiScaler.scale(18)
    readonly property real stepperButton: root.sizeTouch
    readonly property real stepperButtonS: UiScaler.scale(40)
    readonly property real stepperButtonL: UiScaler.scale(56)
    readonly property real stepperValueMinWidth: UiScaler.scale(42)
    readonly property real stepperValueMinWidthS: UiScaler.scale(76)
    readonly property real stepperUnitGapL: root.space1

    // Chips. Heights: ChoiceChip and TagChip; small ChoiceChip and InputChip;
    // FilterChip and ChoiceChip in a grid
    readonly property real chipHeight: UiScaler.scale(40)
    readonly property real chipHeightS: UiScaler.scale(36)
    readonly property real chipHeightL: root.sizeTouch
    readonly property real chipPadding: UiScaler.scale(14)
    readonly property real chipDotPadding: UiScaler.scale(10)
    readonly property real chipDot: root.space3
    readonly property real filterChipPadding: root.space4
    readonly property real filterChipIconPadding: root.space3
    readonly property real filterChipBadge: UiScaler.scale(26)
    readonly property real filterChipBadgePadding: UiScaler.scale(9)
    readonly property real tagChipPaddingStart: root.space3
    readonly property real inputChipPaddingStart: root.space3
    readonly property real inputChipPaddingEnd: root.space1
    readonly property real inputChipRemove: UiScaler.scale(30)

    // TagPill padding, default and large
    readonly property real tagPillPaddingV: UiScaler.scale(2)
    readonly property real tagPillPaddingH: UiScaler.scale(9)
    readonly property real tagPillPaddingVL: UiScaler.scale(5)
    readonly property real tagPillPaddingHL: root.space3

    // IconBadge: discs and tiles, and the tiles' radii
    readonly property real badgeDiscXS: UiScaler.scale(30)
    readonly property real badgeDiscS: UiScaler.scale(36)
    readonly property real badgeDiscM: UiScaler.scale(40)
    readonly property real badgeDiscL: root.sizeTouch
    readonly property real badgeTileS: UiScaler.scale(40)
    readonly property real badgeTileM: UiScaler.scale(56)
    readonly property real badgeTileL: UiScaler.scale(64)
    readonly property real badgeTileRadiusS: root.radiusSm
    readonly property real badgeTileRadiusM: root.radiusMd
    readonly property real badgeTileRadiusL: UiScaler.scale(24)

    // Thumbnail, small
    readonly property real thumbnailSizeS: root.sizeTouch

    // SpecStrip: vertical padding, cell side padding
    readonly property real specStripPaddingV: UiScaler.scale(14)
    readonly property real specCellPadding: root.space3

    // SplitBar: bar height, gap between segments, outer radius; bar to the
    // lines, between lines
    readonly property real splitBarHeight: root.space3
    readonly property real splitBarGap: UiScaler.scale(3)
    readonly property real splitBarRadius: UiScaler.scale(6)
    readonly property real splitBarLinesGap: root.space3
    readonly property real splitBarLineSpacing: root.space1

    // BottomNav: height above the safe area; active indicator; icon to label
    readonly property real bottomNavHeight: UiScaler.scale(80)
    readonly property real bottomNavIndicatorWidth: UiScaler.scale(60)
    readonly property real bottomNavIndicatorHeight: root.space8
    readonly property real bottomNavLabelGap: root.space1

    // BottomSheet: room above a tall sheet; padding (more at the bottom when
    // it ends with a large button); gap between blocks; grip
    readonly property real sheetTopGap: UiScaler.scale(52)
    readonly property real sheetPaddingTop: root.space3
    readonly property real sheetPaddingH: root.space5
    readonly property real sheetPaddingBottom: root.space6
    readonly property real sheetPaddingBottomCta: UiScaler.scale(28)
    readonly property real sheetGap: root.space4
    readonly property real sheetGripWidth: UiScaler.scale(40)
    readonly property real sheetGripHeight: UiScaler.scale(5)
    readonly property real sheetGripRadius: UiScaler.scale(3)
    readonly property real sheetSubtitleGap: root.space1

    // Snackbar: height, padding, distance to the screen sides and to what it
    // sits above; action pill
    readonly property real snackbarHeight: UiScaler.scale(56)
    readonly property real snackbarPaddingStart: UiScaler.scale(18)
    readonly property real snackbarPaddingEnd: root.space2
    readonly property real snackbarMargin: root.space4
    readonly property real snackbarActionHeight: UiScaler.scale(40)
    readonly property real snackbarActionPadding: root.space4

    // EmptyState
    readonly property real emptyPaddingV: UiScaler.scale(48)
    readonly property real emptyPaddingH: root.space8
    readonly property real emptyGap: root.space5
}
