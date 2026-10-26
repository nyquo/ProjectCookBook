#include "core/catalogView.hpp"

#include "core/text.hpp"

#include <algorithm>
#include <limits>
#include <string>
#include <unordered_map>

namespace core {

std::vector<CatalogEntry> catalogView(
  const std::vector<Aisle>& aisles,
  const std::vector<Ingredient>& ingredients,
  std::string_view search,
  std::optional<std::string_view> aisleId,
  const NameLess& less)
{
  std::unordered_map<std::string_view, int> aisleIndex;
  for (int i = 0; i < static_cast<int>(aisles.size()); ++i) {
    aisleIndex.emplace(aisles[i].id, i);
  }
  const std::string query = canonicalName(search);

  std::vector<CatalogEntry> entries;
  for (int i = 0; i < static_cast<int>(ingredients.size()); ++i) {
    const Ingredient& ingredient = ingredients[i];
    if (!ingredient.inCatalog) {
      continue;
    }
    if (aisleId && ingredient.aisleId != *aisleId) {
      continue;
    }
    if (!query.empty() &&
        ingredient.canonicalName.find(query) == std::string::npos) {
      continue;
    }
    int aisle = -1;
    if (ingredient.aisleId) {
      if (const auto it = aisleIndex.find(*ingredient.aisleId);
          it != aisleIndex.end()) {
        aisle = it->second;
      }
    }
    entries.push_back({ i, aisle });
  }

  // "Other" sorts after every aisle
  const auto groupRank = [](const CatalogEntry& entry) {
    return entry.aisle >= 0 ? entry.aisle : std::numeric_limits<int>::max();
  };
  std::ranges::sort(entries, [&](const CatalogEntry& a, const CatalogEntry& b) {
    if (groupRank(a) != groupRank(b)) {
      return groupRank(a) < groupRank(b);
    }
    const Ingredient& first = ingredients[a.ingredient];
    const Ingredient& second = ingredients[b.ingredient];
    if (less(first.name, second.name)) {
      return true;
    }
    if (less(second.name, first.name)) {
      return false;
    }
    return first.id < second.id;
  });
  return entries;
}

}
