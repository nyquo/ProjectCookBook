import QtQuick
import Plating

// A containment mask that lets a control smaller than sizeTouch take presses
// up to sizeTouch around its center, without taking that room in a layout:
// containmentMask: TouchTarget { target: control }
QtObject {
    id: mask

    required property Item target

    function contains(point: point): bool {
        const dx = Math.max(0, (UiMetrics.sizeTouch - mask.target.width) / 2)
        const dy = Math.max(0, (UiMetrics.sizeTouch - mask.target.height) / 2)
        return point.x >= -dx && point.x <= mask.target.width + dx
            && point.y >= -dy && point.y <= mask.target.height + dy
    }
}
