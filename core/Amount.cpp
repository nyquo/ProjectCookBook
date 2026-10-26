#include "core/Amount.hpp"

#include <array>
#include <utility>

namespace core {

// In Unit order
static constexpr std::array<std::string_view, 11> unitCodes{
  "pcs", "g", "kg", "ml", "cl", "l", "pack", "bunch", "oz", "lb", "fl_oz"
};

std::string_view unitCode(Unit unit)
{
  return unitCodes[std::to_underlying(unit)];
}

std::optional<Unit> unitFromCode(std::string_view code)
{
  for (std::size_t i = 0; i < unitCodes.size(); ++i) {
    if (unitCodes[i] == code) {
      return static_cast<Unit>(i);
    }
  }
  return std::nullopt;
}

}
