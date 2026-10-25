import QtQuick
import QtQuick.Effects
import Plating

// A rounded picture cropped to fill. Without one (or until it loads), up to two
// initials in the color family's ink on its fill.
Item {
    id: thumbnail

    enum Size {
        // 62
        Default,
        // 44
        Small
    }

    property int size: Thumbnail.Default
    property url source
    property string initials
    property colorFamily family

    readonly property bool small: thumbnail.size === Thumbnail.Small
    readonly property real radius: thumbnail.small ? UiMetrics.radiusSm : UiMetrics.radiusMd

    implicitWidth: thumbnail.small ? UiMetrics.thumbnailSizeS : UiMetrics.sizeThumb
    implicitHeight: implicitWidth

    Rectangle {
        anchors.fill: parent
        visible: image.status !== Image.Ready
        radius: thumbnail.radius
        color: thumbnail.family.fill

        Text {
            anchors.centerIn: parent
            // Two characters, not two UTF-16 units
            text: Array.from(thumbnail.initials).slice(0, 2).join("")
            font: thumbnail.small ? UiTypography.initialsS : UiTypography.initials
            color: thumbnail.family.ink
        }
    }

    Image {
        id: image

        anchors.fill: parent
        visible: false
        source: thumbnail.source
        sourceSize: Qt.size(thumbnail.width, thumbnail.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Rectangle {
        id: mask

        anchors.fill: parent
        visible: false
        layer.enabled: true
        radius: thumbnail.radius
    }

    MultiEffect {
        anchors.fill: parent
        visible: image.status === Image.Ready
        source: image
        maskEnabled: true
        maskSource: mask
        // A soft threshold keeps the rounded corners antialiased
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1
    }
}
