# Plating

The app's own Qt Quick Controls style, design tokens and generic components: a static QML module, URI `Plating`. It never links or includes `core`, nor the app's components (`CookbookUi`, in `app/ui/`). Its component names and APIs say nothing about recipes.

| Folder | Holds |
| --- | --- |
| `theme/` | The theme contract and its two themes, the `Plating` attached type, the `colorFamily` value type, metrics, typography and motion |
| `icons/` | `Icon` and the `UiIcons` name-to-glyph lookup |
| `parts/` | Building blocks the components share, also open to the app's components: `FocusRing`, `PressOverlay`, `TouchTarget`, `DashedOutline`, `RaisedShadow`, `MenuPanel` |
| `utils/` | `UiScaler` |
| `controls/` | The components, from `QtQuick.Templates` (or `Control` when no template fits) |
| `fonts/` | Bricolage Grotesque and its license |

Controls Plating doesn't implement yet come from the Basic style (`IMPORTS QtQuick.Controls.Basic`). Until they're replaced, `ApplicationWindow` maps its `palette` from the theme so they stay readable in both themes.

The showcase (`showcase/`, `.\scripts\run.ps1 desktop -Showcase`) shows every component in its variants and states.

## Using it

The app links `plating` and `platingplugin`, calls `Q_IMPORT_QML_PLUGIN(PlatingPlugin)` (a static QML module is otherwise dropped by the linker), and calls `QQuickStyle::setStyle("Plating")` before loading QML, so a stray `import QtQuick.Controls` gets Plating too. App QML imports `Plating` directly; that import also provides the Basic controls.

## Components

Presentational: properties in, signals out. They hold no data and format nothing: callers pass display strings ("1,2 kg", "1 h 15").

| Group | Components |
| --- | --- |
| Actions | `Button`, `IconButton`, `FloatingActionButton` |
| Structure | `ScreenHeader`, `SectionHeader`, `ListGroup`, `ListRow` |
| Inputs | `TextField`, `SearchField`, `TextArea`, `TitleField`, `ComboBox` (the design's Select), `CheckBox`, `Switch`, `SegmentedControl` and `SegmentedButton`, `Stepper`, `FilterChip`, `ChoiceChip`, `TagChip`, `InputChip`, `ColorSwatch` |
| Display | `TagPill`, `IconBadge`, `Thumbnail`, `SpecStrip`, `SplitBar` |
| Navigation and overlays | `BottomNav` and `BottomNavItem`, `BottomSheet`, `Menu`, `MenuItem` and `MenuSeparator`, `Snackbar`, `EmptyState` |

Conventions:

- Each component declares its own enums: `variant` (`Button.Primary`, `IconButton.Ghost`) and `size` (`Button.Large`, `IconButton.Small`), named as in the design.
- `inset: true`: the control sits on a `surface`, so it fills with `bg` instead.
- Buttons take their icon as Qt's `icon.name` (a `UiIcons` name) or `icon.source`; other components take `iconName` and `iconSource`. Icon-only controls (`IconButton`, `ColorSwatch`, a round `FilterChip`, a non-extended `FloatingActionButton`) don't show `text`: it's their accessible name. `IconButton`, `ColorSwatch` and `FloatingActionButton` warn when it's empty.
- Items given to a slot (`trailing`, `leading`, `headerAction`, `footer`, `valueItem`…) are reparented into the component.
- Controls that count or choose are controlled: `Stepper` emits `decreaseClicked()` and `increaseClicked()`, the caller changes `text` and says when an end is reached (`canDecrease`, `canIncrease`).
- A dot "in a color family" (`SectionHeader`, `ChoiceChip`) is a `dotColor` the caller picks; `TagChip` draws its dot in the family's fill, as designed.
- Lists of things to show are models with documented roles: `SpecStrip` takes `label`, `value` and `detail` from any model; `SplitBar` takes an array of parts, since it adds their amounts.
- `Menu.openUnder(item)` opens a menu under an item. A `Snackbar` lives once per window: `show(message, actionText)`.
- Exclusive choices use Qt's mechanisms: `autoExclusive` or a `ButtonGroup` for chips, `SegmentedControl.currentIndex`.
- A color family is a `colorFamily` value, already resolved for the theme: `({ fill: theme.tagMint, ink: theme.tagMintInk })`.
- Disabled is 40% opacity unless the component has its own look (`IconButton`).
- Every QML file outside `theme/` imports `Plating` itself, as Qt's own styles do. Without it, tools reading a component from another module (qmllint, qmlcachegen) can't resolve the types it takes from the other folders.

## Theme

```qml
ApplicationWindow {
    Plating.theme: Application.styleHints.colorScheme === Qt.ColorScheme.Dark
                   ? DefaultDarkTheme : DefaultLightTheme
}
```

- `Plating.theme` can be set on any Item, Window or Popup. Everything below inherits it: child items, child windows, popups (drawers and bottom sheets too).
- A popup inherits from its **window**, not from the item that declares it (Qt's propagation rule). To give a popup another theme, set `Plating.theme` on the popup itself.
- An explicit value wins over the inherited one. Assigning `undefined` (or `null`) returns to the inherited one. Reparenting re-inherits.
- When no ancestor sets it, the theme is `DefaultLightTheme`.

**Reading it.** `Plating.theme` is a `QObject*`, because `UiTheme` is defined in QML. Every control reads it once through a typed property and binds to that, so qmllint and qmlcachegen see typed access:

```qml
T.Button {
    id: control
    readonly property UiTheme theme: Plating.theme as UiTheme
    background: Rectangle { color: control.theme.surface }
}
```

**Themes.** `UiTheme` is the contract: every color is a `required property`, so a theme that misses one fails to instantiate. `LightTheme` and `DarkTheme` are the only files with color values. `DefaultLightTheme` and `DefaultDarkTheme` are singleton instances of them.

**Accent.** `accentChoice` (a `UiTheme.Accent`: Raspberry, Spirulina, Blueberry, Saffron, Basil) picks one of the five accent sets. `accent`, `accentInk`, `accentSoft` and `focus` follow it, and so does the light theme's `shadowRaised`. Nothing else does. The app binds `accentChoice` on both default themes.

**Dark.** `dark` is true in a dark theme. Colors that are app data rather than tokens, such as tag and aisle colors, come with a light and a dark variant; QML picks one with it: `theme.dark ? darkFill : fill`.

**Color families.** The design's four `tag-*` families (`tagMint`, `tagMintInk` …) are in the theme for chrome (`tagButter` colors note cards) and previews such as the showcase. Data keeps its own colors: the app's tags and aisles come from its database, which seeds the same values.

**Pressed.** `pressOverlay` (ink at 8%) covers a pressed light fill, `pressOverlayOnFill` (bg at 12%) a pressed ink, accent or danger fill. `PressOverlay` picks one.

### Token names

Design tokens are kebab-case; properties are camelCase:

| Token | Property |
| --- | --- |
| `ink-muted` | `inkMuted` |
| `on-danger` | `dangerInk` |
| `accent-basil`, `accent-basil-on`, `accent-basil-soft` | `accentBasil`, `accentBasilInk`, `accentBasilSoft` |
| `accent`, `on-accent`, `accent-soft`, `focus` | `accent`, `accentInk`, `accentSoft`, `focus`: read-only, resolved from `accentChoice` |
| `tag-mint`, `tag-mint-ink` | `tagMint`, `tagMintInk` |
| `shadow-raised` | `shadowRaised` (color); its geometry is in `UiMetrics` |
| `space-4`, `radius-sheet`, `size-touch` | `UiMetrics.space4`, `UiMetrics.radiusSheet`, `UiMetrics.sizeTouch` |
| `title-xl`, `body-l` | `UiTypography.titleXl`, `UiTypography.bodyL` |

`on-x` becomes `xInk` because `onAccent:` would parse as a signal handler.

## Metrics and typography

Sizes don't change with the theme, so they're singletons. Their px values (design px) appear nowhere else.

- `UiMetrics`: spacing, radii, sizes, the focus ring and the shadow geometry, already passed through `UiScaler`, then opacities. The scale comes first; each component's geometry follows in its own group (`buttonHeightL`, `listRowDisc`…), reusing the scale where the values match. `hairline` (1 px) and opacities aren't scaled.
- `UiTypography`: the design's styles, completed by size and weight: `labelBold` is `label` (15/600) at 700, `captionExtraBold` is `caption` (13/500) at 800. Styles that wrap also have a line height:
  - `bodyL`: a `font`, Bricolage Grotesque with the size, weight and letter spacing, scaled. `makeFont()` builds it.
  - `bodyLLineHeight`: its line height in px. `lineHeight()` computes it from a multiple of the font size.

  Use the line height with `Text.FixedHeight`. Qt's `Text.ProportionalHeight` multiplies the font's own line spacing (1.2 × the size for this font), not the size.

  ```qml
  Text {
      font: UiTypography.bodyL
      lineHeightMode: Text.FixedHeight
      lineHeight: UiTypography.bodyLLineHeight
  }
  ```

- **Variable font axes.** Every style also sets the font's `opsz` and `wght` axes through `font.variableAxes`, because Qt sets neither by itself:
  - Without `opsz`, every size would use the 14 pt optical size of the font's named instances. Browsers set it to the px size, and so do the styles.
  - Without `wght`, weight 650 (`bodyLStrong`) would snap to a named weight.

## Motion

`UiMotion` holds every duration and the decelerating curve (`easing.type: Easing.Bezier; easing.bezierCurve: UiMotion.decelerate`). Its `reduced` switch is the only one: the app sets it. Animations take their duration through it:

- `UiMotion.move(ms)` for anything that moves, scales or resizes: 0 with reduced motion;
- `UiMotion.fade(ms)` for opacity: at most 120 ms with reduced motion.

So with reduced motion, each animation becomes a short fade. Numbers that change never animate.

## Icons

`Icon` draws an interface glyph by `name`, looked up in `UiIcons`, with Qt Quick Shapes' curve renderer (sharp and antialiased at any size), or a single-color SVG file by `source`, drawn in black and recolored with `MultiEffect`. Glyphs sit on a 24-unit grid; their strokes are in screen px whatever the icon's size (`UiMetrics.iconStroke…`). An SVG file keeps its own stroke, which scales with it.

The glyphs are placeholders until the icon family is chosen: swap the paths in `UiIcons`, or make `Icon` load one SVG file per name.

## Scaler

`UiScaler` turns design px into window px:

- `designSize` is 1920 × 1080. The app feeds `actualSize` from its root window's size.
- `scaleToScreenSize` is off by default. Android already lays out in dp; ratio scaling is meant for desktop.
- When it's on, `sizeScale` is the smaller of the width and height ratios; otherwise it's 1.
- `UiScaler.scale(px)` is QML on purpose: a binding that calls it re-evaluates when `sizeScale` changes.

Font sizes round to whole pixels: QFont takes integer pixel sizes. Letter spacing is in 1/64 px.

## Adding a control

1. Copy Qt's Basic implementation (`<Qt>/<kit>/qml/QtQuick/Controls/Basic/<Control>.qml`) to `controls/`, derived from `QtQuick.Templates`.
2. Import `Plating`. Add the typed `theme` property and take colors from it, sizes from `UiMetrics`, fonts from `UiTypography` and durations from `UiMotion`.
3. Use the parts: `PressOverlay` for the pressed state, `FocusRing` for keyboard focus, `TouchTarget` when the control is smaller than `sizeTouch`.
4. Keep Basic's safe-area handling, if it has any.
5. List the file in `QML_FILES` in `CMakeLists.txt`, and show it in the showcase.

## Font

Bricolage Grotesque, SIL Open Font License 1.1 (`fonts/OFL.txt`), from the google/fonts repository (`ofl/bricolagegrotesque`). The file was renamed from `BricolageGrotesque[opsz,wdth,wght].ttf`, because brackets and commas are awkward in CMake lists and resource URLs.

The family name is read from the `FontLoader`: the font's legacy name is "Bricolage Grotesque 96pt ExtraBold".
