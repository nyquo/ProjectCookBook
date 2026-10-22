# Plating

The app's own Qt Quick Controls style and design tokens: a static QML module, URI `Plating`. It never links or includes `core`.

| Folder | Holds |
| --- | --- |
| `theme/` | The theme contract and its two themes, the `Plating` attached type, metrics and typography |
| `utils/` | `UiScaler` |
| `controls/` | The controls Plating implements, from `QtQuick.Templates`: `ApplicationWindow`, `Page` |
| `fonts/` | Bricolage Grotesque and its license |

Controls Plating doesn't implement yet come from the Basic style (`IMPORTS QtQuick.Controls.Basic`). Until they're replaced, `ApplicationWindow` maps its `palette` from the theme so they stay readable in both themes.

## Using it

The app links `plating` and `platingplugin`, calls `Q_IMPORT_QML_PLUGIN(PlatingPlugin)` (a static QML module is otherwise dropped by the linker), and calls `QQuickStyle::setStyle("Plating")` before loading QML, so a stray `import QtQuick.Controls` gets Plating too. App QML imports `Plating` directly; that import also provides the Basic controls.

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

**Dark.** `dark` is true in a dark theme. Colors that are app data rather than tokens, such as tag and aisle colors, come with a light and a dark variant; QML picks one with it: `theme.dark ? darkFill : fill`. The design's `tag-*` tokens aren't in the theme for that reason: they're the app's default tag colors, seeded in its database.

### Token names

Design tokens are kebab-case; properties are camelCase:

| Token | Property |
| --- | --- |
| `ink-muted` | `inkMuted` |
| `on-danger` | `dangerInk` |
| `accent-basil`, `accent-basil-on`, `accent-basil-soft` | `accentBasil`, `accentBasilInk`, `accentBasilSoft` |
| `accent`, `on-accent`, `accent-soft`, `focus` | `accent`, `accentInk`, `accentSoft`, `focus`: read-only, resolved from `accentChoice` |
| `shadow-raised` | `shadowRaised` (color); its geometry is in `UiMetrics` |
| `space-4`, `radius-sheet`, `size-touch` | `UiMetrics.space4`, `UiMetrics.radiusSheet`, `UiMetrics.sizeTouch` |
| `title-xl`, `body-l` | `UiTypography.titleXl`, `UiTypography.bodyL` |

`on-x` becomes `xInk` because `onAccent:` would parse as a signal handler.

## Metrics and typography

Sizes don't change with the theme, so they're singletons. Their px values (design px) appear nowhere else.

- `UiMetrics`: spacing, radii, sizes, the focus ring and the shadow geometry, already passed through `UiScaler`. `hairline` (1 px) isn't scaled.
- `UiTypography`: two properties per text style:
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

## Scaler

`UiScaler` turns design px into window px:

- `designSize` is 1920 × 1080. The app feeds `actualSize` from its root window's size.
- `scaleToScreenSize` is off by default. Android already lays out in dp; ratio scaling is meant for desktop.
- When it's on, `sizeScale` is the smaller of the width and height ratios; otherwise it's 1.
- `UiScaler.scale(px)` is QML on purpose: a binding that calls it re-evaluates when `sizeScale` changes.

Font sizes round to whole pixels: QFont takes integer pixel sizes. Letter spacing is in 1/64 px.

## Adding a control

1. Copy Qt's Basic implementation (`<Qt>/<kit>/qml/QtQuick/Controls/Basic/<Control>.qml`) to `controls/`, derived from `QtQuick.Templates`.
2. Add the typed `theme` property and take colors from it, sizes from `UiMetrics`, and fonts from `UiTypography`.
3. Keep Basic's safe-area handling, if it has any.
4. List the file in `QML_FILES` in `CMakeLists.txt`.

## Font

Bricolage Grotesque, SIL Open Font License 1.1 (`fonts/OFL.txt`), from the google/fonts repository (`ofl/bricolagegrotesque`). The file was renamed from `BricolageGrotesque[opsz,wdth,wght].ttf`, because brackets and commas are awkward in CMake lists and resource URLs.

The family name is read from the `FontLoader`: the font's legacy name is "Bricolage Grotesque 96pt ExtraBold".
