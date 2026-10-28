#pragma once

#include <string>
#include <string_view>
#include <vector>

namespace core {

class SettingStore;
class TagStore;

// The filters the recipes list opens with. They're a personal preference, so
// they're settings, not flags on the tags.

// Stored under "default_favorites_only" as "true" or "false"; off when unset
// or unknown
bool defaultFavoritesOnly(const SettingStore& settings);
void setDefaultFavoritesOnly(SettingStore& settings, bool on);

// The live tags among those stored under "default_tag_ids", comma-separated,
// in stored order. A deleted tag's id stays stored, so restoring the tag
// brings it back into the defaults.
std::vector<std::string> defaultTagIds(const SettingStore& settings,
                                       const TagStore& tags);
// Keeps the other stored ids, deleted tags' included. Throws
// std::invalid_argument for an id that isn't a live tag's.
void setDefaultTagSelected(SettingStore& settings,
                           const TagStore& tags,
                           std::string_view tagId,
                           bool selected);

}
