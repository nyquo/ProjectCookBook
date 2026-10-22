#include "core/ThemedColors.hpp"

#include <doctest/doctest.h>

#include <optional>

TEST_CASE("A color's text is #rrggbb in lowercase")
{
  CHECK(core::toText({ 0x00, 0x00, 0x00 }) == "#000000");
  CHECK(core::toText({ 0x0a, 0xbc, 0xff }) == "#0abcff");
}

TEST_CASE("Every channel value survives a round trip through text")
{
  for (int value = 0; value <= 255; ++value) {
    const auto v = static_cast<std::uint8_t>(value);
    for (const core::Rgb color :
         { core::Rgb{ v, 0, 0 }, core::Rgb{ 0, v, 0 }, core::Rgb{ 0, 0, v } }) {
      REQUIRE(core::rgbFromText(core::toText(color)) == color);
    }
  }
}

TEST_CASE("Parsing accepts only #rrggbb in lowercase")
{
  CHECK(core::rgbFromText("#0abcff") == core::Rgb{ 0x0a, 0xbc, 0xff });

  for (const char* text : { "",
                            "#",
                            "#0abcf",
                            "#0abcff0",
                            "0abcff",
                            "#0ABCFF",
                            "#0abcfg",
                            " #0abcff",
                            "#0abcff ",
                            "#-1bcff",
                            "#0x0abc" }) {
    CAPTURE(text);
    CHECK(core::rgbFromText(text) == std::nullopt);
  }
}
