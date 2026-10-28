pragma Singleton

import QtQuick
import Plating

// The app components' own text styles, built like UiTypography's
QtObject {
    id: root

    // QuantityField's amount
    readonly property font quantityInput: UiTypography.makeFont(30, 800, -0.03)
    // A step's number; edited, it's titleS
    readonly property font stepNumber: UiTypography.makeFont(20, 800, 0)
    // A step's text while edited: body-l with taller lines, to fit the mentions
    readonly property real stepTextEditLineHeight: UiTypography.lineHeight(UiTypography.bodyL, 1.75)
    // A recipe's initial over its header, without a photo
    readonly property font headerInitial: UiTypography.makeFont(110, 800, 0)
}
