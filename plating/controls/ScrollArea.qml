pragma ComponentBehavior: Bound

import QtQuick
import Plating

// A scrolling area with its own feel, instead of Flickable's drag and flick:
// the content follows the finger (or the mouse) exactly, then glides on and
// slows down at a steady rate; past an edge, a drag stretches at half speed
// and springs back; a glide stops at the edge. The wheel scrolls by steps. A
// thin indicator shows the position while it moves.
//
// It scrolls the items given to it, in a Flickable of its own (set
// contentHeight, or contentWidth when horizontal), or a Flickable or ListView
// given as `view`, e.g. for delegates. That Flickable never takes input itself.
//
// With pullDownEnabled, a drag that starts at the top and goes down doesn't
// stretch: it reports a pull instead (pulledDown()), e.g. to close a screen.
// With yieldsAtStart, the area doesn't take that drag at all: what holds it
// gets it, e.g. a BottomSheet swiped down.
Item {
    id: control

    readonly property UiTheme theme: Plating.theme as UiTheme

    // Qt.Vertical or Qt.Horizontal
    property int orientation: Qt.Vertical
    // A Flickable or a ListView to scroll instead of the area's own: it's
    // reparented into the area, which it fills
    property Flickable view
    property alias contentWidth: own.contentWidth
    property alias contentHeight: own.contentHeight
    property bool pullDownEnabled: false
    property bool yieldsAtStart: false
    default property alias content: own.flickableData

    // What's scrolled: `view`, or the area's own Flickable
    readonly property Flickable flickable: control.view ?? own
    readonly property bool vertical: control.orientation === Qt.Vertical
    // The content position (the Flickable's contentY, or contentX) and its
    // range, margins included
    readonly property real position: control.vertical ? control.flickable.contentY : control.flickable.contentX
    readonly property real minimum: control.vertical ? control.flickable.originY - control.flickable.topMargin
                                                     : control.flickable.originX - control.flickable.leftMargin
    readonly property real maximum: Math.max(control.minimum, control.vertical
        ? control.flickable.originY + control.flickable.contentHeight + control.flickable.bottomMargin
          - control.flickable.height
        : control.flickable.originX + control.flickable.contentWidth + control.flickable.rightMargin
          - control.flickable.width)
    readonly property bool scrollable: control.maximum > control.minimum
    readonly property bool atBeginning: control.position <= control.minimum
    // Dragged, gliding, or springing back
    readonly property bool moving: drag.active || glide.running || settle.running

    // While a drag that started at the top goes down: how far, which is
    // UiMotion.scrollEdgeResistance of the finger's travel
    signal pulledDown(real distance)
    // That drag ended
    signal pullDownReleased

    // Scrolls to a content position, within the range, stopping any motion
    function scrollTo(position: real) {
        control.stop()
        control.place(control.clamped(position))
    }

    function stop() {
        glide.stop()
        settle.stop()
    }

    function place(position: real) {
        if (control.vertical)
            control.flickable.contentY = position
        else
            control.flickable.contentX = position
    }

    function clamped(position: real): real {
        return Math.max(control.minimum, Math.min(position, control.maximum))
    }

    // Past an edge, the content moves at scrollEdgeResistance of the drag
    function resisted(position: real): real {
        if (position < control.minimum)
            return control.minimum - (control.minimum - position) * UiMotion.scrollEdgeResistance
        if (position > control.maximum)
            return control.maximum + (position - control.maximum) * UiMotion.scrollEdgeResistance
        return position
    }

    function pointer(): real {
        return control.vertical ? drag.centroid.scenePosition.y : drag.centroid.scenePosition.x
    }

    function beginDrag() {
        control.stop()
        motion.dragged = control.position
        motion.pointer = control.pointer()
        motion.samples = []
        motion.pulling = control.pullDownEnabled && control.atBeginning
        motion.pull = 0
    }

    function dragMove() {
        const now = control.pointer()
        // The finger's travel, positive downwards or rightwards
        let travel = now - motion.pointer
        motion.pointer = now
        if (motion.pulling) {
            const pull = motion.pull + travel * UiMotion.scrollEdgeResistance
            if (pull > 0) {
                motion.pull = pull
                control.pulledDown(pull)
                return
            }
            if (motion.pull > 0) {
                // Back up past the start: what's left scrolls
                travel = pull / UiMotion.scrollEdgeResistance
                motion.pull = 0
                control.pulledDown(0)
            }
        }
        if (!control.scrollable)
            return
        motion.dragged -= travel
        control.place(control.resisted(motion.dragged))
        const time = Date.now()
        motion.samples = motion.samples.filter(sample => time - sample.time <= 2 * UiMotion.scrollSampleTime)
                                       .concat([{ time: time, position: motion.dragged }])
    }

    function endDrag() {
        if (motion.pulling && motion.pull > 0) {
            motion.pulling = false
            motion.pull = 0
            control.pullDownReleased()
            return
        }
        motion.pulling = false
        if (control.position < control.minimum || control.position > control.maximum) {
            settle.to = control.clamped(control.position)
            settle.restart()
            return
        }
        motion.velocity = control.releaseVelocity()
        if (Math.abs(motion.velocity) >= UiMotion.scrollStopSpeed)
            glide.start()
    }

    // In px per ms of content position, over the drag's last moments; 0 if
    // the finger had stopped
    function releaseVelocity(): real {
        const now = Date.now()
        const samples = motion.samples
        if (samples.length === 0 || now - samples[samples.length - 1].time > UiMotion.scrollSampleTime)
            return 0
        let first = samples[0]
        for (const sample of samples) {
            if (now - sample.time > UiMotion.scrollSampleTime)
                first = sample
        }
        const last = samples[samples.length - 1]
        return last.time > first.time ? (last.position - first.position) / (last.time - first.time) : 0
    }

    implicitWidth: Math.max(0, own.contentWidth)
    implicitHeight: Math.max(0, own.contentHeight)

    // Content that shrank leaves the position past the end
    onMaximumChanged: {
        if (!control.moving && control.position > control.maximum)
            control.place(control.maximum)
    }
    onViewChanged: {
        if (!control.view)
            return
        control.view.parent = control
        control.view.anchors.fill = control
        control.view.interactive = false
    }
    onPositionChanged: {
        indicator.shown = true
        indicatorTimer.restart()
    }

    QtObject {
        id: motion

        // The drag's position before the edges' resistance
        property real dragged: 0
        // The pointer's last position along the axis, in the scene
        property real pointer: 0
        // [{ time, position }], to measure the release velocity
        property var samples: []
        property real velocity: 0
        // A pull down from the top, while the drag lasts
        property bool pulling: false
        property real pull: 0
        // The current touch went towards the start from there: it's left to
        // what holds the area (yieldsAtStart)
        property bool yielding: false
    }

    // Under the content: the content's own wheel handling goes first, e.g. a
    // horizontal row inside
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            const shifted = wheel.modifiers & Qt.ShiftModifier
            const step = notches => notches / 120 * UiMetrics.scrollWheelStep
            const x = wheel.pixelDelta.x !== 0 ? wheel.pixelDelta.x : step(wheel.angleDelta.x)
            const y = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : step(wheel.angleDelta.y)
            const delta = control.vertical ? (shifted ? 0 : y) : (x !== 0 ? x : shifted ? y : 0)
            const target = control.clamped(control.position - delta)
            // Unused, it goes on to what's under the area
            wheel.accepted = target !== control.position
            if (wheel.accepted)
                control.scrollTo(target)
        }
    }

    Flickable {
        id: own

        anchors.fill: parent
        visible: control.view === null
        interactive: false
    }

    DragHandler {
        id: drag

        target: null
        enabled: (control.scrollable || control.pullDownEnabled) && !motion.yielding
        xAxis.enabled: !control.vertical
        yAxis.enabled: control.vertical
        acceptedDevices: PointerDevice.TouchScreen | PointerDevice.Mouse | PointerDevice.Stylus

        onActiveChanged: drag.active ? control.beginDrag() : control.endDrag()
        onCentroidChanged: {
            if (drag.active)
                control.dragMove()
        }
        // A touch stops a glide
        onGrabChanged: (transition, point) => {
            if (point.state === EventPoint.Pressed)
                control.stop()
        }
    }

    // Watches each touch before the drag takes it: declared after it, since
    // Qt gives an item's handlers each event last declared first
    PointHandler {
        id: watch

        enabled: control.yieldsAtStart
        acceptedDevices: drag.acceptedDevices

        onActiveChanged: {
            if (!watch.active)
                motion.yielding = false
        }
        onPointChanged: {
            if (!watch.active || drag.active || !control.atBeginning)
                return
            const travel = control.vertical ? watch.point.scenePosition.y - watch.point.scenePressPosition.y
                                            : watch.point.scenePosition.x - watch.point.scenePressPosition.x
            if (travel > 0)
                motion.yielding = true
        }
    }

    // Slows down by scrollFriction every 1/60 s, until it stops or reaches an
    // edge
    FrameAnimation {
        id: glide

        onTriggered: {
            const elapsed = glide.frameTime * 1000
            motion.velocity *= Math.pow(UiMotion.scrollFriction, elapsed * 60 / 1000)
            const next = control.position + motion.velocity * elapsed
            control.place(control.clamped(next))
            if (next <= control.minimum || next >= control.maximum
                    || Math.abs(motion.velocity) < UiMotion.scrollStopSpeed)
                glide.stop()
        }
    }

    // Back within the range after a drag past an edge
    NumberAnimation {
        id: settle

        target: control.flickable
        property: control.vertical ? "contentY" : "contentX"
        duration: UiMotion.move(UiMotion.scrollSettle)
        easing.type: Easing.Bezier
        easing.bezierCurve: UiMotion.decelerate
    }

    Rectangle {
        id: indicator

        property bool shown: false

        readonly property real extent: control.vertical ? control.height : control.width
        readonly property real track: indicator.extent - 2 * UiMetrics.scrollIndicatorMargin
        // The visible part's share of the whole
        readonly property real length: Math.max(UiMetrics.scrollIndicatorMinLength,
                                                indicator.track * indicator.extent
                                                / (indicator.extent + control.maximum - control.minimum))
        readonly property real offset: UiMetrics.scrollIndicatorMargin + (indicator.track - indicator.length)
                                       * (control.clamped(control.position) - control.minimum)
                                       / Math.max(1, control.maximum - control.minimum)

        // Over a view given to the area, which comes after it
        z: 1
        x: control.vertical ? control.width - width - UiMetrics.scrollIndicatorMargin : indicator.offset
        y: control.vertical ? indicator.offset : control.height - height - UiMetrics.scrollIndicatorMargin
        width: control.vertical ? UiMetrics.scrollIndicatorThickness : indicator.length
        height: control.vertical ? indicator.length : UiMetrics.scrollIndicatorThickness
        radius: UiMetrics.scrollIndicatorThickness / 2
        visible: control.scrollable && indicator.opacity > 0
        color: control.theme.inkMuted
        opacity: indicator.shown ? UiMetrics.opacityScrollIndicator : 0

        Behavior on opacity {
            NumberAnimation {
                duration: UiMotion.fade(UiMotion.scrollIndicatorFade)
            }
        }

        Timer {
            id: indicatorTimer

            interval: UiMotion.scrollIndicatorStay
            onTriggered: {
                if (control.moving)
                    indicatorTimer.restart()
                else
                    indicator.shown = false
            }
        }
    }
}
