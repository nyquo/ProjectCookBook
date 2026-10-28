#include "core/appearance.hpp"

#include "core/SettingStore.hpp"

#include <array>
#include <string_view>
#include <utility>

namespace core {

static constexpr std::string_view themeModeKey = "theme";
static constexpr std::string_view accentKey = "accent";

// In enum order
static constexpr std::array<std::string_view, 3> themeModeCodes{ "system",
                                                                 "light",
                                                                 "dark" };
static constexpr std::array<std::string_view, 5> accentCodes{ "raspberry",
                                                              "spirulina",
                                                              "blueberry",
                                                              "saffron",
                                                              "basil" };

ThemeMode themeMode(const SettingStore& settings)
{
  return static_cast<ThemeMode>(
    settings.codeIndex(themeModeKey, themeModeCodes));
}

void setThemeMode(SettingStore& settings, ThemeMode mode)
{
  settings.setValue(themeModeKey, themeModeCodes[std::to_underlying(mode)]);
}

Accent accent(const SettingStore& settings)
{
  return static_cast<Accent>(settings.codeIndex(accentKey, accentCodes));
}

void setAccent(SettingStore& settings, Accent accent)
{
  settings.setValue(accentKey, accentCodes[std::to_underlying(accent)]);
}

}
