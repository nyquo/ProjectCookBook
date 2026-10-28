import QtQuick
import Plating

// A pill field that adds what's typed: an accent + inside it on the right,
// off while the field is blank. The + and the keyboard's Enter emit
// addClicked(); the caller adds the item and clears `text`. The field keeps
// focus, so the keyboard stays up for the next one.
TextField {
    id: control

    // The +'s accessible name ("Add tag")
    property string actionText: qsTr("Add")

    readonly property bool blank: control.text.trim() === ""

    signal addClicked

    rightPadding: UiMetrics.textFieldActionPadding + UiMetrics.iconButtonSizeS + UiMetrics.textFieldIconGap

    onAccepted: {
        if (!control.blank)
            control.addClicked()
    }

    IconButton {
        x: control.width - width - UiMetrics.textFieldActionPadding
        y: control.topPadding + (control.pillHeight - height) / 2
        size: IconButton.Small
        variant: IconButton.Accent
        enabled: !control.blank
        icon.source: CookbookIcons.source("plus")
        text: control.actionText
        // Keeps the keyboard up
        focusPolicy: Qt.NoFocus
        onClicked: control.addClicked()
    }
}
