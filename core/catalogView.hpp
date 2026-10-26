#pragma once

#include "core/Aisle.hpp"
#include "core/Ingredient.hpp"

#include <functional>
#include <optional>
#include <string_view>
#include <vector>

namespace core {

// A catalog item as shown, by index in the lists catalogView() was given
struct CatalogEntry
{
  int ingredient;
  // The aisle it shows under, or -1 for "Other": no aisle, or a deleted one
  int aisle;

  bool operator==(const CatalogEntry&) const = default;
};

// Orders display names, e.g. by the user's locale
using NameLess = std::function<bool(std::string_view, std::string_view)>;

// The catalog items to show: grouped by aisle in the aisles' order, "Other"
// last, and by name within a group (ties by id). `search` keeps the items
// whose canonical name contains search's; `aisleId` keeps one aisle's.
std::vector<CatalogEntry> catalogView(
  const std::vector<Aisle>& aisles,
  const std::vector<Ingredient>& ingredients,
  std::string_view search,
  std::optional<std::string_view> aisleId,
  const NameLess& less);

}
