#include "core/Tag.hpp"

#include <array>
#include <utility>

namespace core {

// In TagFamily order
static constexpr std::array<std::string_view, tagFamilyCount>
  tagFamilyCodes{ "mint", "butter", "sky", "peach" };

std::string_view tagFamilyCode(TagFamily family)
{
  return tagFamilyCodes[std::to_underlying(family)];
}

std::optional<TagFamily> tagFamilyFromCode(std::string_view code)
{
  for (std::size_t i = 0; i < tagFamilyCodes.size(); ++i) {
    if (tagFamilyCodes[i] == code) {
      return static_cast<TagFamily>(i);
    }
  }
  return std::nullopt;
}

}
