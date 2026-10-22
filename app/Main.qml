import QtQuick
import QtQuick.Layouts
import Plating

ApplicationWindow {
    id: window

    // Phone-like size for desktop previews; ignored on Android (always fullscreen)
    width: 400
    height: 760
    visible: true
    title: AppInfo.name

    // Follows the system until the theme setting exists; devThemeRow overrides
    // it meanwhile (Unknown = System).
    // TODO: when the app's theme differs from the system's, the status bar icons
    // keep the system's contrast and can become unreadable.
    Plating.theme: {
        const scheme = devThemeRow.scheme !== Qt.ColorScheme.Unknown
                       ? devThemeRow.scheme : Application.styleHints.colorScheme
        return scheme === Qt.ColorScheme.Dark ? DefaultDarkTheme : DefaultLightTheme
    }

    Binding {
        target: UiScaler
        property: "actualSize"
        value: Qt.size(window.width, window.height)
    }
    Binding {
        target: DefaultLightTheme
        property: "accentChoice"
        value: devThemeRow.accentChoice
    }
    Binding {
        target: DefaultDarkTheme
        property: "accentChoice"
        value: devThemeRow.accentChoice
    }

    Page {
        anchors.fill: parent

        header: Label {
            padding: UiMetrics.space4
            text: window.title
            font: UiTypography.titleL
        }

        AislesScreen {
            anchors.fill: parent
            anchors.leftMargin: UiMetrics.space4
            anchors.rightMargin: UiMetrics.space4
        }

        footer: ColumnLayout {
            spacing: 0

            // TEMPORARY: remove with the theme and accent settings
            DevThemeRow {
                id: devThemeRow

                Layout.fillWidth: true
                Layout.margins: UiMetrics.space2
            }

            Label {
                Layout.fillWidth: true
                padding: UiMetrics.space2
                opacity: 0.7
                elide: Text.ElideRight
                font: UiTypography.caption
                text: `${AppInfo.platform} · ${AppInfo.cpuArchitecture} · `
                      + qsTr("v%1 · Qt %2").arg(AppInfo.version).arg(AppInfo.qtVersion)
            }
        }
    }
}
