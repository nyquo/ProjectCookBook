#include "core/tagView.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>

#include <string>
#include <vector>

namespace {

using Names = std::vector<std::string>;

core::Tag tag(std::string id, std::string name)
{
  return { std::move(id), name, name, core::TagFamily::Mint, test::seedTime };
}

// Byte order: enough for these names
bool byteLess(std::string_view a, std::string_view b)
{
  return a < b;
}

Names view(const std::vector<core::Tag>& tags, const core::NameLess& less)
{
  Names names;
  for (const int index : core::tagsByName(tags, less)) {
    names.push_back(tags[index].name + " (" + tags[index].id + ")");
  }
  return names;
}

}

TEST_CASE("Tags show by name, ties by id")
{
  const std::vector<core::Tag> tags{ tag("1", "Weeknight"),
                                     tag("4", "Brunch"),
                                     tag("3", "Vegetarian"),
                                     tag("2", "Brunch") };

  CHECK(view(tags, byteLess) ==
        Names{ "Brunch (2)", "Brunch (4)", "Vegetarian (3)", "Weeknight (1)" });
  CHECK(view({}, byteLess).empty());
}

TEST_CASE("The name order comes from the caller")
{
  const auto byLength = [](std::string_view a, std::string_view b) {
    return a.size() < b.size();
  };
  const std::vector<core::Tag> tags{ tag("1", "Weeknight"),
                                     tag("2", "Quick"),
                                     tag("3", "Kids") };

  CHECK(view(tags, byLength) ==
        Names{ "Kids (3)", "Quick (2)", "Weeknight (1)" });
}
