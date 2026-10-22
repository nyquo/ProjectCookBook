import QtQuick
import QtQuick.Templates as T

T.ApplicationWindow {
    id: window

    readonly property UiTheme theme: Plating.theme as UiTheme

    color: window.theme.bg
    font: UiTypography.bodyL
}
