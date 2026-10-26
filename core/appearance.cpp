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

// The stored value's index in `codes`, or 0, the default
template<std::size_t size>
static std::size_t storedIndex(const SettingStore& settings,
                               std::string_view key,
                               const std::array<std::string_view, size>& codes)
{
  const std::optional<std::string> value = settings.value(key);
  for (std::size_t i = 0; value && i < size; ++i) {
    if (codes[i] == *value) {
      return i;
    }
  }
  return 0;
}

ThemeMode themeMode(const SettingStore& settings)
{
  return static_cast<ThemeMode>(
    storedIndex(settings, themeModeKey, themeModeCodes));
}

void setThemeMode(SettingStore& settings, ThemeMode mode)
{
  settings.setValue(themeModeKey, themeModeCodes[std::to_underlying(mode)]);
}

Accent accent(const SettingStore& settings)
{
  return static_cast<Accent>(storedIndex(settings, accentKey, accentCodes));
}

void setAccent(SettingStore& settings, Accent accent)
{
  settings.setValue(accentKey, accentCodes[std::to_underlying(accent)]);
}

}
