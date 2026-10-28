#pragma once

#include "core/Amount.hpp"
#include "core/clock.hpp"

#include <optional>
#include <string>

namespace core {

// A live ingredient: an entry of the ingredient dictionary, and a catalog item
// while inCatalog
struct Ingredient
{
  std::string id;
  // Trimmed, as the user typed it
  std::string name;
  // canonicalName(name): unique among live ingredients
  std::string canonicalName;
  // Possibly a deleted aisle's: the ingredient then shows under "Other"
  std::optional<std::string> aisleId;
  // An icon key; without one the UI shows its default icon
  std::optional<std::string> icon;
  // What one tap adds to the shopping list
  std::optional<Amount> oneTap;
  // A catalog item always has a live aisle and a one-tap amount
  bool inCatalog = false;
  Timestamp modifiedAt;

  bool operator==(const Ingredient&) const = default;
};

}
