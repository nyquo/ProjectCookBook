#include "core/defaultFilters.hpp"

#include "core/SettingStore.hpp"
#include "core/TagStore.hpp"

#include <algorithm>
#include <ranges>
#include <stdexcept>

namespace core {

static constexpr std::string_view favoritesOnlyKey = "default_favorites_only";
static constexpr std::string_view tagIdsKey = "default_tag_ids";

static bool isLiveTag(const TagStore& tags, std::string_view id)
{
  return std::ranges::find(tags.tags(), id, &Tag::id) != tags.tags().end();
}

// Without empty or repeated ids, which only a stray write could leave
static std::vector<std::string> storedTagIds(const SettingStore& settings)
{
  std::vector<std::string> ids;
  const std::string value = settings.value(tagIdsKey).value_or("");
  for (const auto part : std::views::split(value, ',')) {
    std::string id(part.begin(), part.end());
    if (!id.empty() && std::ranges::find(ids, id) == ids.end()) {
      ids.push_back(std::move(id));
    }
  }
  return ids;
}

bool defaultFavoritesOnly(const SettingStore& settings)
{
  return settings.flag(favoritesOnlyKey, false);
}

void setDefaultFavoritesOnly(SettingStore& settings, bool on)
{
  settings.setFlag(favoritesOnlyKey, on);
}

std::vector<std::string> defaultTagIds(const SettingStore& settings,
                                       const TagStore& tags)
{
  std::vector<std::string> ids = storedTagIds(settings);
  std::erase_if(ids,
                [&](const std::string& id) { return !isLiveTag(tags, id); });
  return ids;
}

void setDefaultTagSelected(SettingStore& settings,
                           const TagStore& tags,
                           std::string_view tagId,
                           bool selected)
{
  if (!isLiveTag(tags, tagId)) {
    throw std::invalid_argument(
      "setDefaultTagSelected: no live tag with this id");
  }
  std::vector<std::string> ids = storedTagIds(settings);
  const auto it = std::ranges::find(ids, tagId);
  if (selected == (it != ids.end())) {
    return;
  }
  if (selected) {
    ids.emplace_back(tagId);
  } else {
    ids.erase(it);
  }

  std::string value;
  for (const std::string& id : ids) {
    if (!value.empty()) {
      value += ',';
    }
    value += id;
  }
  settings.setValue(tagIdsKey, value);
}

}
