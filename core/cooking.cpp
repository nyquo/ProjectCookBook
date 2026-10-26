#include "core/cooking.hpp"

#include "core/SettingStore.hpp"

#include <string_view>

namespace core {

static constexpr std::string_view keepScreenOnKey = "keep_screen_on";

bool keepScreenOn(const SettingStore& settings)
{
  return settings.flag(keepScreenOnKey, true);
}

void setKeepScreenOn(SettingStore& settings, bool on)
{
  settings.setFlag(keepScreenOnKey, on);
}

}
