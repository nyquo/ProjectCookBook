#pragma once

namespace core {

class SettingStore;

enum class ThemeMode
{
  // Follows the system's light or dark mode, live
  System,
  Light,
  Dark
};

// The accent colors the user can pick, by name; the UI owns their values
enum class Accent
{
  Raspberry,
  Spirulina,
  Blueberry,
  Saffron,
  Basil
};

// Stored under "theme" as "system", "light" or "dark". System when unset or
// unknown, e.g. written by a newer version.
ThemeMode themeMode(const SettingStore& settings);
void setThemeMode(SettingStore& settings, ThemeMode mode);

// Stored under "accent" as "raspberry", "spirulina"… Raspberry when unset or
// unknown.
Accent accent(const SettingStore& settings);
void setAccent(SettingStore& settings, Accent accent);

}
