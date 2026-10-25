import QtQuick
import QtQuick.Templates as T
import Plating

// A tag, in its color family's fill and ink
T.Label {
    id: control

    enum Size {
        // In lists
        Default,
        // In headers
        Large
    }

    property int size: TagPill.Default
    property colorFamily family

    readonly property bool large: control.size === TagPill.Large

    topPadding: control.large ? UiMetrics.tagPillPaddingVL : UiMetrics.tagPillPaddingV
    bottomPadding: control.topPadding
    leftPadding: control.large ? UiMetrics.tagPillPaddingHL : UiMetrics.tagPillPaddingH
    rightPadding: control.leftPadding
    font: control.large ? UiTypography.tagL : UiTypography.tag
    color: control.family.ink

    background: Rectangle {
        radius: height / 2
        color: control.family.fill
    }
}
