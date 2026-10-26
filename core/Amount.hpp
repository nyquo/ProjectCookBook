#pragma once

#include <optional>
#include <string_view>

namespace core {

enum class Unit
{
  Pieces,
  Grams,
  Kilograms,
  Milliliters,
  Centiliters,
  Liters,
  Packs,
  Bunches
};

// The language-neutral code tables store: "pcs", "g", "kg", "ml", "cl", "l",
// "pack", "bunch"
std::string_view unitCode(Unit unit);
std::optional<Unit> unitFromCode(std::string_view code);

// A quantity in a unit, e.g. what one tap adds to the shopping list
struct Amount
{
  double quantity;
  Unit unit;

  bool operator==(const Amount&) const = default;
};

}
