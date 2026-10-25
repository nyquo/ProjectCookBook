pragma Singleton

import QtQuick

// The interface icons, by name: line glyphs on a 24-unit grid, drawn by Icon
// with round caps and joins. These are placeholders until the icon family is
// chosen: swapping it means replacing the paths below, or making Icon load one
// SVG file per name.
QtObject {
    id: root

    // The glyph grid
    readonly property real gridSize: 24

    // name: { path, stroke (if not UiMetrics.iconStroke) }. A glyph whose path
    // closes can be filled (Icon.filled), e.g. heart.
    readonly property var glyphs: ({
        "plus": { path: "M12 5v14 M5 12h14" },
        "minus": { path: "M5 12h14" },
        "close": { path: "M6 6l12 12 M18 6L6 18" },
        "check": { path: "M5 12.5l4.5 4.5L19 7.5" },
        "back": { path: "M15 5l-7 7l7 7" },
        "chevron-right": { path: "M9 5l7 7l-7 7" },
        "chevron-down": { path: "M6 9l6 6l6-6" },
        "arrow-right": { path: "M5 12h14 M13 6l6 6l-6 6" },
        "arrow-up": { path: "M12 19V5 M6 11l6-6l6 6" },
        "arrow-down": { path: "M12 5v14 M6 13l6 6l6-6" },
        "trash": { path: "M5 7h14 M10 7V4.5h4V7 M7 7l1 13h8l1-13 M10.5 11v5.5 M13.5 11v5.5" },
        "edit": { path: "M4 20h4L19 9l-4-4L4 16z M13.5 6.5l4 4" },
        "more": { path: "M5.5 12h.01 M12 12h.01 M18.5 12h.01", stroke: UiMetrics.iconStrokeDots },
        "drag": { path: "M9 6h.01 M15 6h.01 M9 12h.01 M15 12h.01 M9 18h.01 M15 18h.01", stroke: UiMetrics.iconStrokeDots },
        "dot": { path: "M12 12h.01", stroke: UiMetrics.iconStrokeDot },
        "search": { path: "M4 11a7 7 0 1 0 14 0a7 7 0 1 0-14 0 M20 20l-4.2-4.2" },
        "filter": { path: "M4 7h9 M17 7h3 M4 17h3 M11 17h9 M15 5v4 M9 15v4" },
        "sort": { path: "M7 5v14 M4 16l3 3l3-3 M17 19V5 M14 8l3-3l3 3" },
        "heart": { path: "M12 20s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7a4.3 4.3 0 0 1 7.5 2.8C19.5 15.4 12 20 12 20z" },
        "clock": { path: "M12 3.5a8.5 8.5 0 1 0 0 17a8.5 8.5 0 1 0 0-17 M12 7.5V12l3 2" },
        "calendar": { path: "M4 6.5h16V20H4z M4 10.5h16 M8.5 3.5v5 M15.5 3.5v5" },
        "book": { path: "M6 4h12v16H8a2 2 0 0 1-2-2z M6 16a2 2 0 0 1 2-2h10 M10 8h4" },
        "basket": { path: "M3.5 9.5h17l-1.8 10H5.3z M8 9.5l3.5-6 M16 9.5l-3.5-6 M9.5 13v3.5 M14.5 13v3.5" },
        "link": { path: "M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1 M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1" },
        "download": { path: "M12 4v11 M7.5 10.5L12 15l4.5-4.5 M5 15v4h14v-4" },
        "upload": { path: "M12 15V4 M7.5 8.5L12 4l4.5 4.5 M5 15v4h14v-4" },
        "settings": {
            path: "M8.56 5.93Q9.02 5.67 9.25 4.34L9.31 4Q9.53 2.72 10.83 2.72L13.17 2.72Q14.47 2.72 14.69 4L14.75 4.34Q14.98 5.67 15.44 5.93L15.54 5.99Q15.99 6.25 17.26 5.79L17.58 5.67Q18.8 5.22 19.45 6.35L20.62 8.37Q21.27 9.5 20.27 10.33L20.01 10.55Q18.98 11.42 18.98 11.94L18.98 12.06Q18.98 12.58 20.01 13.45L20.27 13.67Q21.27 14.5 20.62 15.63L19.45 17.65Q18.8 18.78 17.58 18.33L17.26 18.21Q15.99 17.75 15.54 18.01L15.44 18.07Q14.98 18.33 14.75 19.66L14.69 20Q14.47 21.28 13.17 21.28L10.83 21.28Q9.53 21.28 9.31 20L9.25 19.66Q9.02 18.33 8.56 18.07L8.46 18.01Q8.01 17.75 6.74 18.21L6.42 18.33Q5.2 18.78 4.55 17.65L3.38 15.63Q2.73 14.5 3.73 13.67L3.99 13.45Q5.02 12.58 5.02 12.06L5.02 11.94Q5.02 11.42 3.99 10.55L3.73 10.33Q2.73 9.5 3.38 8.37L4.55 6.35Q5.2 5.22 6.42 5.67L6.74 5.79Q8.01 6.25 8.46 5.99Z M12 9.1 a2.9 2.9 0 1 0 0 5.8 a2.9 2.9 0 1 0 0 -5.8",
            stroke: UiMetrics.iconStrokeSettings
        }
    })

    // The glyph's SVG path data, or "" for an unknown name
    function path(name: string): string {
        const glyph = root.glyphs[name]
        if (glyph === undefined) {
            console.warn(`UiIcons: no icon named "${name}"`)
            return ""
        }
        return glyph.path
    }

    // The glyph's own stroke width, already scaled
    function strokeOf(name: string): real {
        const glyph = root.glyphs[name]
        return glyph?.stroke ?? UiMetrics.iconStroke
    }
}
