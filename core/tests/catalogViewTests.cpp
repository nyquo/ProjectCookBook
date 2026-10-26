#include "core/catalogView.hpp"
#include "core/text.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>

#include <optional>
#include <string>
#include <vector>

namespace {

using Names = std::vector<std::string>;

core::Aisle aisle(std::string id, std::string name)
{
  return { std::move(id), std::move(name), test::someColors, test::seedTime };
}

core::Ingredient item(std::string id,
                      std::string name,
                      std::optional<std::string> aisleId,
                      bool inCatalog = true)
{
  std::string canonical = core::canonicalName(name);
  return {
    std::move(id),      std::move(name), std::move(canonical),
    std::move(aisleId), std::nullopt,    core::Amount{ 1, core::Unit::Pieces },
    inCatalog,          test::seedTime
  };
}

// Byte order: enough for these names
bool byteLess(std::string_view a, std::string_view b)
{
  return a < b;
}

struct Fixture
{
  std::vector<core::Aisle> aisles{ aisle("a", "Produce"), aisle("b", "Dairy") };
  std::vector<core::Ingredient> items{
    item("1", "Milk", "b"),
    item("2", "Pears", "a"),
    item("3", "Apples", "a"),
    item("4", "Crème fraîche", "b"),
    item("5", "Tofu", std::nullopt),
    item("6", "Bread", "gone"), // a deleted aisle's
    item("7", "Basil", "a", false),
  };

  // "name (aisle index)" for each entry
  Names view(std::string_view search = {},
             std::optional<std::string_view> aisleId = std::nullopt) const
  {
    Names result;
    for (const core::CatalogEntry& entry :
         core::catalogView(aisles, items, search, aisleId, byteLess)) {
      result.push_back(items[entry.ingredient].name + " (" +
                       std::to_string(entry.aisle) + ")");
    }
    return result;
  }
};

}

TEST_CASE_FIXTURE(Fixture,
                  "Catalog items are grouped in aisle order, Other last, "
                  "sorted by name")
{
  CHECK(view() == Names{ "Apples (0)",
                         "Pears (0)",
                         "Crème fraîche (1)",
                         "Milk (1)",
                         "Bread (-1)",
                         "Tofu (-1)" });

  std::swap(aisles[0], aisles[1]);
  CHECK(view() == Names{ "Crème fraîche (0)",
                         "Milk (0)",
                         "Apples (1)",
                         "Pears (1)",
                         "Bread (-1)",
                         "Tofu (-1)" });
}

TEST_CASE_FIXTURE(Fixture, "The name order comes from the caller")
{
  const auto byLength = [](std::string_view a, std::string_view b) {
    return a.size() < b.size();
  };
  items.push_back(item("8", "Kale", "a"));
  items.push_back(item("0", "Leek", "a")); // ties keep id order

  Names names;
  for (const core::CatalogEntry& entry :
       core::catalogView(aisles, items, {}, "a", byLength)) {
    names.push_back(items[entry.ingredient].name);
  }
  CHECK(names == Names{ "Leek", "Kale", "Pears", "Apples" });
}

TEST_CASE_FIXTURE(Fixture, "Search matches canonical names")
{
  CHECK(view("creme") == Names{ "Crème fraîche (1)" });
  CHECK(view("  FRAÎCHE ") == Names{ "Crème fraîche (1)" });
  CHECK(view("e") ==
        Names{ "Apples (0)", "Pears (0)", "Crème fraîche (1)", "Bread (-1)" });
  CHECK(view("basil").empty()); // not in the catalog
  CHECK(view(" ") == view());
}

TEST_CASE_FIXTURE(Fixture, "The aisle filter keeps one aisle's items")
{
  CHECK(view({}, "a") == Names{ "Apples (0)", "Pears (0)" });
  CHECK(view("milk", "a").empty());
  CHECK(view({}, "nowhere").empty());
}
