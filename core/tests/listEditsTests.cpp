#include "core/listEdits.hpp"

#include <doctest/doctest.h>

#include <algorithm>
#include <random>
#include <string>
#include <vector>

using core::ListInserted;
using core::ListMoved;
using core::ListRemoved;
using Keys = std::vector<std::string>;
using Edits = std::vector<core::ListEdit>;

namespace {

// Applies the edits as a list model would, inserted rows coming from `after`
Keys applied(Keys rows, const Edits& edits, const Keys& after)
{
  for (const core::ListEdit& edit : edits) {
    if (const auto* removed = std::get_if<ListRemoved>(&edit)) {
      REQUIRE(removed->index < static_cast<int>(rows.size()));
      rows.erase(rows.begin() + removed->index);
    } else if (const auto* inserted = std::get_if<ListInserted>(&edit)) {
      REQUIRE(inserted->index <= static_cast<int>(rows.size()));
      rows.insert(rows.begin() + inserted->index, after[inserted->index]);
    } else {
      const auto& moved = std::get<ListMoved>(edit);
      REQUIRE(moved.from < static_cast<int>(rows.size()));
      REQUIRE(moved.to < static_cast<int>(rows.size()));
      const auto first = rows.begin();
      if (moved.from < moved.to) {
        std::rotate(
          first + moved.from, first + moved.from + 1, first + moved.to + 1);
      } else {
        std::rotate(
          first + moved.to, first + moved.from, first + moved.from + 1);
      }
    }
  }
  return rows;
}

}

TEST_CASE("Equal lists need no edits")
{
  CHECK(core::listEdits({}, {}).empty());
  CHECK(core::listEdits({ "a", "b" }, { "a", "b" }).empty());
}

TEST_CASE("Rows that leave are removed from the end")
{
  CHECK(core::listEdits({ "a", "b", "c", "d" }, { "b", "d" }) ==
        Edits{ ListRemoved{ 2 }, ListRemoved{ 0 } });
}

TEST_CASE("New rows are inserted where they belong")
{
  CHECK(core::listEdits({ "b", "d" }, { "a", "b", "c", "d", "e" }) ==
        Edits{ ListInserted{ 0 }, ListInserted{ 2 }, ListInserted{ 4 } });
}

TEST_CASE("A row that changes place is moved")
{
  CHECK(core::listEdits({ "a", "b", "c" }, { "c", "a", "b" }) ==
        Edits{ ListMoved{ 2, 0 } });
  CHECK(core::listEdits({ "a", "b", "c" }, { "a", "c", "b" }) ==
        Edits{ ListMoved{ 2, 1 } });
}

TEST_CASE("Removals, moves and insertions combine")
{
  const Keys before{ "a", "b", "c", "d", "e" };
  const Keys after{ "e", "x", "b", "d", "y" };
  CHECK(applied(before, core::listEdits(before, after), after) == after);
}

TEST_CASE("Any reordering is reproduced")
{
  std::mt19937 random(42);
  for (int round = 0; round < 200; ++round) {
    Keys before;
    Keys after;
    for (int i = 0; i < 12; ++i) {
      const std::string key(1, static_cast<char>('a' + i));
      if (random() % 4 != 0) {
        before.push_back(key);
      }
      if (random() % 4 != 0) {
        after.push_back(key);
      }
    }
    std::shuffle(before.begin(), before.end(), random);
    std::shuffle(after.begin(), after.end(), random);
    CAPTURE(round);
    CHECK(applied(before, core::listEdits(before, after), after) == after);
  }
}
