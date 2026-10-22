#pragma once

#include "core/ThemedColors.hpp"
#include "core/clock.hpp"

#include <string>

namespace core {

// A live tag color; its position is its index in TagColorStore::tagColors()
struct TagColor
{
  std::string id;
  std::string name;
  ThemedColors colors;
  Timestamp modifiedAt;

  bool operator==(const TagColor&) const = default;
};

}
