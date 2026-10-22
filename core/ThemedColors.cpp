#include "core/ThemedColors.hpp"

#include "core/Database.hpp"

#include <sqlite3.h>

#include <format>

namespace core {

static std::optional<std::uint8_t> lowercaseHexDigit(char c)
{
  if (c >= '0' && c <= '9') {
    return static_cast<std::uint8_t>(c - '0');
  }
  if (c >= 'a' && c <= 'f') {
    return static_cast<std::uint8_t>(c - 'a' + 10);
  }
  return std::nullopt;
}

static Rgb rgbColumn(const Statement& statement, int index)
{
  const std::string text = statement.columnText(index);
  if (const auto color = rgbFromText(text)) {
    return *color;
  }
  throw DatabaseError(SQLITE_CORRUPT, "invalid color '" + text + "'");
}

std::string toText(Rgb color)
{
  return std::format("#{:02x}{:02x}{:02x}", color.red, color.green, color.blue);
}

std::optional<Rgb> rgbFromText(std::string_view text)
{
  if (text.size() != 7 || text[0] != '#') {
    return std::nullopt;
  }
  std::uint8_t channels[3];
  for (int i = 0; i < 3; ++i) {
    const auto high = lowercaseHexDigit(text[1 + 2 * i]);
    const auto low = lowercaseHexDigit(text[2 + 2 * i]);
    if (!high || !low) {
      return std::nullopt;
    }
    channels[i] = static_cast<std::uint8_t>(*high * 16 + *low);
  }
  return Rgb{ channels[0], channels[1], channels[2] };
}

ThemedColors themedColorsColumns(const Statement& statement, int first)
{
  return { rgbColumn(statement, first),
           rgbColumn(statement, first + 1),
           rgbColumn(statement, first + 2),
           rgbColumn(statement, first + 3) };
}

}
