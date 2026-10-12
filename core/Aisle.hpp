#pragma once

#include "core/clock.hpp"

#include <optional>
#include <string>
#include <string_view>
#include <utility>

namespace core {

// Stored as TEXT: keep in sync with the CHECK constraint in core/schema.
enum class AisleColor
{
  Mint,
  Butter,
  Sky,
  Peach
};

inline constexpr AisleColor allAisleColors[] = { AisleColor::Mint,
                                                 AisleColor::Butter,
                                                 AisleColor::Sky,
                                                 AisleColor::Peach };

constexpr std::string_view toText(AisleColor color)
{
  switch (color) {
    case AisleColor::Mint:
      return "mint";
    case AisleColor::Butter:
      return "butter";
    case AisleColor::Sky:
      return "sky";
    case AisleColor::Peach:
      return "peach";
  }
  std::unreachable();
}

constexpr std::optional<AisleColor> aisleColorFromText(std::string_view text)
{
  for (AisleColor color : allAisleColors) {
    if (toText(color) == text) {
      return color;
    }
  }
  return std::nullopt;
}

// A live aisle; its position is its index in AisleStore::aisles().
struct Aisle
{
  std::string id;
  std::string name;
  AisleColor color;
  Timestamp modifiedAt;

  bool operator==(const Aisle&) const = default;
};

}
