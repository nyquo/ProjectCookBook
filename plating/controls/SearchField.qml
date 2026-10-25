import QtQuick
import Plating

// A TextField with a search icon and a clear button. Its placeholder says what
// it searches ("Search recipes").
TextField {
    leadingIcon: "search"
    trailingAction: TextField.Clear
    // Filters as the user types, rather than when a word is committed
    inputMethodHints: Qt.ImhNoPredictiveText
}
