#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>

namespace core {

class Statement;

// An opaque sRGB color
struct Rgb
{
  std::uint8_t red;
  std::uint8_t green;
  std::uint8_t blue;

  bool operator==(const Rgb&) const = default;
};

// "#rrggbb" in lowercase: the only form the schema's CHECK constraints accept,
// and the only one rgbFromText() parses.
std::string toText(Rgb color);
std::optional<Rgb> rgbFromText(std::string_view text);

// A fill and the ink (text, icons) drawn on it, for each theme. Tables store
// them as four "#rrggbb" columns, in this order: fill, ink, dark_fill,
// dark_ink.
struct ThemedColors
{
  Rgb fill;
  Rgb ink;
  Rgb darkFill;
  Rgb darkInk;

  bool operator==(const ThemedColors&) const = default;
};

// Reads the four color columns starting at `first`; throws DatabaseError if
// one isn't "#rrggbb"
ThemedColors themedColorsColumns(const Statement& statement, int first);

}
