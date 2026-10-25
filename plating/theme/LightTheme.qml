import QtQuick

UiTheme {
    id: theme

    dark: false

    bg: "#f5f4f2"
    surface: "#ffffff"
    ink: "#221b24"
    inkMuted: "#655e68"
    line: "#e7e3e6"
    danger: "#b3261e"
    dangerInk: "#ffffff"
    scrim: "#73141016" // rgba(20, 16, 22, 0.45)
    pressOverlay: Qt.alpha(theme.ink, 0.08)
    pressOverlayOnFill: Qt.alpha(theme.bg, 0.12)

    tagMint: "#d9efe2"
    tagMintInk: "#1f5636"
    tagButter: "#f6e9c2"
    tagButterInk: "#5e4600"
    tagSky: "#dce6f7"
    tagSkyInk: "#1f3e73"
    tagPeach: "#f8e0d5"
    tagPeachInk: "#7a3312"

    accentRaspberry: "#c4265e"
    accentRaspberryInk: "#ffffff"
    accentRaspberrySoft: "#f9e4ec"
    accentSpirulina: "#0a6e65"
    accentSpirulinaInk: "#ffffff"
    accentSpirulinaSoft: "#dcf0ec"
    accentBlueberry: "#4b45d6"
    accentBlueberryInk: "#ffffff"
    accentBlueberrySoft: "#e6e5fb"
    accentSaffron: "#a14a06"
    accentSaffronInk: "#ffffff"
    accentSaffronSoft: "#fbe8d4"
    accentBasil: "#29702d"
    accentBasilInk: "#ffffff"
    accentBasilSoft: "#e0f0e0"

    // Tinted with the current accent
    shadowRaised: Qt.alpha(theme.accent, 0.28)
    shadowMenu: "#2e000000" // rgba(0, 0, 0, 0.18)
}
