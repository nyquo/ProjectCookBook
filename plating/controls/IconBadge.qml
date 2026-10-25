import QtQuick
import Plating

// An icon (iconName from UiIcons, or iconSource, a single-color SVG drawn in
// black) in its color family's ink, on the family's fill, as a disc or a
// rounded tile. Muted: on bg, in ink-muted.
Item {
    id: badge

    enum Shape {
        Disc,
        Tile
    }

    // Disc: 30, 36, 40, 44. Tile: 40 (Small and ExtraSmall), 56, 64.
    enum Size {
        ExtraSmall,
        Small,
        Medium,
        Large
    }

    readonly property UiTheme theme: Plating.theme as UiTheme

    property int shape: IconBadge.Disc
    property int size: IconBadge.Medium
    property string iconName
    property url iconSource
    property colorFamily family
    property bool muted: false

    readonly property real side: {
        if (badge.shape === IconBadge.Tile) {
            switch (badge.size) {
            case IconBadge.Medium:
                return UiMetrics.badgeTileM
            case IconBadge.Large:
                return UiMetrics.badgeTileL
            default:
                return UiMetrics.badgeTileS
            }
        }
        switch (badge.size) {
        case IconBadge.ExtraSmall:
            return UiMetrics.badgeDiscXS
        case IconBadge.Small:
            return UiMetrics.badgeDiscS
        case IconBadge.Large:
            return UiMetrics.badgeDiscL
        default:
            return UiMetrics.badgeDiscM
        }
    }

    implicitWidth: badge.side
    implicitHeight: badge.side

    Rectangle {
        anchors.fill: parent
        radius: {
            if (badge.shape === IconBadge.Disc)
                return width / 2
            switch (badge.size) {
            case IconBadge.Medium:
                return UiMetrics.badgeTileRadiusM
            case IconBadge.Large:
                return UiMetrics.badgeTileRadiusL
            default:
                return UiMetrics.badgeTileRadiusS
            }
        }
        color: badge.muted ? badge.theme.bg : badge.family.fill

        Icon {
            anchors.centerIn: parent
            width: Math.round(badge.side * UiMetrics.badgeIconRatio)
            height: width
            name: badge.iconName
            source: badge.iconSource
            color: badge.muted ? badge.theme.inkMuted : badge.family.ink
        }
    }
}
