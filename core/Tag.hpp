#pragma once

#include "core/clock.hpp"

#include <optional>
#include <string>
#include <string_view>

namespace core {

// The four colors a tag can take: the theme's tag families, which give their
// fill and ink. In this order, ties go to the earlier one.
enum class TagFamily
{
  Mint,
  Butter,
  Sky,
  Peach
};

inline constexpr int tagFamilyCount = 4;

// The language-neutral code the tag table stores: "mint", "butter", "sky",
// "peach"
std::string_view tagFamilyCode(TagFamily family);
std::optional<TagFamily> tagFamilyFromCode(std::string_view code);

// A live tag
struct Tag
{
  std::string id;
  // Trimmed, as the user typed it
  std::string name;
  // canonicalName(name): unique among live tags
  std::string canonicalName;
  TagFamily color;
  Timestamp modifiedAt;

  bool operator==(const Tag&) const = default;
};

}
