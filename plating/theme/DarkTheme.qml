import QtQuick

UiTheme {
    id: theme

    dark: true

    bg: "#141214"
    surface: "#1f1c20"
    ink: "#f3eff3"
    inkMuted: "#aca4ae"
    line: "#2f2a30"
    danger: "#ffb4ab"
    dangerInk: "#410e0b"
    scrim: "#99000000" // rgba(0, 0, 0, 0.6)
    pressOverlay: Qt.alpha(theme.ink, 0.08)
    pressOverlayOnFill: Qt.alpha(theme.bg, 0.12)

    tagMint: "#1c3327"
    tagMintInk: "#a3ddba"
    tagButter: "#342d16"
    tagButterInk: "#edd68a"
    tagSky: "#1c273d"
    tagSkyInk: "#afc8f5"
    tagPeach: "#3b241b"
    tagPeachInk: "#f6b89c"

    accentRaspberry: "#ff7eaa"
    accentRaspberryInk: "#2b0917"
    accentRaspberrySoft: "#3a1e2b"
    accentSpirulina: "#4fd1c0"
    accentSpirulinaInk: "#032521"
    accentSpirulinaSoft: "#16332f"
    accentBlueberry: "#9c98ff"
    accentBlueberryInk: "#13113f"
    accentBlueberrySoft: "#25234a"
    accentSaffron: "#fbbf6a"
    accentSaffronInk: "#2e1a00"
    accentSaffronSoft: "#3a2a12"
    accentBasil: "#86d48a"
    accentBasilInk: "#0b2a0d"
    accentBasilSoft: "#1b3320"

    shadowRaised: "#80000000" // rgba(0, 0, 0, 0.5)
    shadowMenu: "#2e000000" // rgba(0, 0, 0, 0.18)
}
