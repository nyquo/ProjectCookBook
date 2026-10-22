#pragma once

#include "core/ThemedColors.hpp"
#include "core/clock.hpp"

#include <string>

namespace core {

// A live aisle; its position is its index in AisleStore::aisles()
struct Aisle
{
  std::string id;
  std::string name;
  ThemedColors colors;
  Timestamp modifiedAt;

  bool operator==(const Aisle&) const = default;
};

}
