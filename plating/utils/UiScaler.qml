pragma Singleton

import QtQuick

QtObject {
    id: root

    // The screen size the design was drawn for
    property size designSize: Qt.size(1920, 1080)
    // Bound to the size of the current screen to make the widgets change their size dynamically
    // depending on the screen definition
    property size actualSize: root.designSize
    property bool scaleToScreenSize: false
    property real sizeScale: 1.0

    function scale(value: real): real {
        if(!root.scaleToScreenSize) {
            return value * root.sizeScale;
        }
        const dynamicSizeScale = Math.min(root.actualSize.width / root.designSize.width,
                                     root.actualSize.height / root.designSize.height);
        return value * dynamicSizeScale;
    }
}
