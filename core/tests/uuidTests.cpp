#include "core/UuidV7Generator.hpp"

#include <doctest/doctest.h>

#include <algorithm>
#include <set>
#include <string>

TEST_CASE("A UUIDv7 holds the timestamp, version and variant")
{
  core::UuidV7Generator generator(42);
  const std::string id = generator.next(core::fromMillis(0x01a11df5a400));

  REQUIRE(id.size() == 36);
  CHECK(id.substr(0, 13) == "01a11df5-a400");
  CHECK(id[8] == '-');
  CHECK(id[13] == '-');
  CHECK(id[18] == '-');
  CHECK(id[23] == '-');
  CHECK(id[14] == '7');                             // version
  CHECK(std::string_view("89ab").contains(id[19])); // variant bits 10
  CHECK(std::ranges::all_of(id, [](char c) {
    return c == '-' || (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f');
  }));
}

TEST_CASE("UUIDv7s are unique and sort by creation time")
{
  core::UuidV7Generator generator;
  std::set<std::string> ids;
  std::string previous;
  for (int i = 0; i < 1000; ++i) {
    const std::string id = generator.next(core::fromMillis(1791504000000 + i));
    CHECK(id > previous);
    previous = id;
    ids.insert(id);
  }
  CHECK(ids.size() == 1000);
}

TEST_CASE("Generators with the same seed produce the same ids")
{
  core::UuidV7Generator a(7);
  core::UuidV7Generator b(7);
  const core::Timestamp time = core::fromMillis(1791504000000);
  CHECK(a.next(time) == b.next(time));
  CHECK(a.next(time) != a.next(time));
}
