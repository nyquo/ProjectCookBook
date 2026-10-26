#pragma once

namespace core {

class SettingStore;

// Whether an open recipe keeps the display awake. Stored under
// "keep_screen_on" as "true" or "false"; on when unset or unknown.
bool keepScreenOn(const SettingStore& settings);
void setKeepScreenOn(SettingStore& settings, bool on);

}
