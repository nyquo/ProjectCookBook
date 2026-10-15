# TODO

## Decisions to take

- **How colors are handled.** Today `core::AisleColor` is an enum stored as TEXT, mirrored by `AisleListModel::Color`, and `AislesScreen.qml` only shows its name: no actual color value exists anywhere yet. To decide:
  - where the palette (enum value → actual color, light and dark) lives: a global color class (C++ singleton exposed to QML, or a QML `Theme` singleton), or something else;
  - whether `AisleColor` stays aisle-specific or becomes a shared color enum that other tables reuse.

## Others

- Think about onboarding