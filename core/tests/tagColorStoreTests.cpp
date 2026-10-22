#include "core/TagColorStore.hpp"
#include "testSupport.hpp"

#include <doctest/doctest.h>
#include <sqlite3.h>

namespace {

using Names = std::vector<std::string>;

Names names(const core::TagColorStore& store)
{
  Names result;
  for (const core::TagColor& tagColor : store.tagColors()) {
    result.push_back(tagColor.name);
  }
  return result;
}

}

TEST_CASE("Loading reads the live tag colors in position order")
{
  core::Database db(":memory:");
  const core::TagColorStore store(test::migrated(db));

  CHECK(
    names(store) ==
    Names{
      "Rose", "Peach", "Butter", "Mint", "Aqua", "Sky", "Lavender", "Oat" });
  CHECK(store.tagColors()[2] ==
        core::TagColor{ "01a11df5-a406-73dc-a362-c8802db18945",
                        "Butter",
                        test::butter,
                        test::seedTime });
}

TEST_CASE("Loading skips deleted tag colors and orders ties by id")
{
  core::Database db(":memory:");
  test::migrated(db).exec(
    "UPDATE tag_color SET deleted = 1 WHERE name = 'Peach';"
    "UPDATE tag_color SET position = 0 WHERE name IN ('Mint', 'Sky');"
    "UPDATE tag_color SET position = 9 WHERE name = 'Rose'");

  const core::TagColorStore store(db);

  CHECK(names(store) ==
        Names{ "Mint", "Sky", "Butter", "Aqua", "Lavender", "Oat", "Rose" });
}

TEST_CASE("A stored color the schema would refuse fails loading")
{
  core::Database db(":memory:");
  test::migrated(db).exec(
    "PRAGMA ignore_check_constraints = ON;"
    "UPDATE tag_color SET dark_ink = '#ABCDEF' WHERE name = 'Sky';"
    "PRAGMA ignore_check_constraints = OFF");

  CHECK(test::errorCode([&] { (void)core::TagColorStore(db); }) ==
        SQLITE_CORRUPT);
}
