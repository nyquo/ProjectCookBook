#include "core/text.hpp"

#include <array>
#include <cstddef>

namespace core {

static bool isAsciiSpace(char c)
{
  return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' ||
         c == '\v';
}

// U+00C0 to U+017F, lowercase and without accents. "" keeps the character: ×
// and ÷ are the only ones that aren't letters.
// clang-format off
static constexpr std::array<std::string_view, 0x180 - 0xc0> latinFolds{
  /* U+00C0 */ "a", "a", "a", "a", "a", "a", "ae", "c", "e", "e", "e", "e", "i", "i", "i", "i",
  /* U+00D0 */ "d", "n", "o", "o", "o", "o", "o", "", "o", "u", "u", "u", "u", "y", "th", "ss",
  /* U+00E0 */ "a", "a", "a", "a", "a", "a", "ae", "c", "e", "e", "e", "e", "i", "i", "i", "i",
  /* U+00F0 */ "d", "n", "o", "o", "o", "o", "o", "", "o", "u", "u", "u", "u", "y", "th", "y",
  /* U+0100 */ "a", "a", "a", "a", "a", "a", "c", "c", "c", "c", "c", "c", "c", "c", "d", "d",
  /* U+0110 */ "d", "d", "e", "e", "e", "e", "e", "e", "e", "e", "e", "e", "g", "g", "g", "g",
  /* U+0120 */ "g", "g", "g", "g", "h", "h", "h", "h", "i", "i", "i", "i", "i", "i", "i", "i",
  /* U+0130 */ "i", "i", "ij", "ij", "j", "j", "k", "k", "k", "l", "l", "l", "l", "l", "l", "l",
  /* U+0140 */ "l", "l", "l", "n", "n", "n", "n", "n", "n", "n", "n", "n", "o", "o", "o", "o",
  /* U+0150 */ "o", "o", "oe", "oe", "r", "r", "r", "r", "r", "r", "s", "s", "s", "s", "s", "s",
  /* U+0160 */ "s", "s", "t", "t", "t", "t", "t", "t", "u", "u", "u", "u", "u", "u", "u", "u",
  /* U+0170 */ "u", "u", "u", "u", "w", "w", "y", "y", "y", "z", "z", "z", "z", "z", "z", "s",
};
// clang-format on

struct CodePoint
{
  char32_t value;
  // Bytes it takes; an invalid byte counts as one, with valid false
  std::size_t length;
  bool valid;
};

static CodePoint decodeUtf8(std::string_view text)
{
  const auto byte = [&](std::size_t i) {
    return static_cast<unsigned char>(text[i]);
  };
  const unsigned char lead = byte(0);
  if (lead < 0x80) {
    return { lead, 1, true };
  }

  std::size_t length = 0;
  char32_t value = 0;
  char32_t smallest = 0;
  if ((lead & 0xe0) == 0xc0) {
    length = 2;
    value = lead & 0x1f;
    smallest = 0x80;
  } else if ((lead & 0xf0) == 0xe0) {
    length = 3;
    value = lead & 0x0f;
    smallest = 0x800;
  } else if ((lead & 0xf8) == 0xf0) {
    length = 4;
    value = lead & 0x07;
    smallest = 0x10000;
  } else {
    return { lead, 1, false };
  }
  if (text.size() < length) {
    return { lead, 1, false };
  }
  for (std::size_t i = 1; i < length; ++i) {
    if ((byte(i) & 0xc0) != 0x80) {
      return { lead, 1, false };
    }
    value = (value << 6) | (byte(i) & 0x3f);
  }
  // Overlong forms, surrogates and values past Unicode are invalid
  if (value < smallest || value > 0x10ffff ||
      (value >= 0xd800 && value <= 0xdfff)) {
    return { lead, 1, false };
  }
  return { value, length, true };
}

static bool isSpace(char32_t c)
{
  return c == ' ' || (c >= '\t' && c <= '\r') || c == 0x85 || c == 0xa0 ||
         c == 0x1680 || (c >= 0x2000 && c <= 0x200a) || c == 0x2028 ||
         c == 0x2029 || c == 0x202f || c == 0x205f || c == 0x3000;
}

static bool isCombiningAccent(char32_t c)
{
  return c >= 0x300 && c <= 0x36f;
}

std::string_view trimmed(std::string_view text)
{
  while (!text.empty() && isAsciiSpace(text.front())) {
    text.remove_prefix(1);
  }
  while (!text.empty() && isAsciiSpace(text.back())) {
    text.remove_suffix(1);
  }
  return text;
}

std::string canonicalName(std::string_view name)
{
  std::string result;
  result.reserve(name.size());
  // Whitespace is written only before the next character, so it never leads
  // or trails
  bool spacePending = false;
  while (!name.empty()) {
    const CodePoint c = decodeUtf8(name);
    const std::string_view bytes = name.substr(0, c.length);
    name.remove_prefix(c.length);

    if (c.valid && isSpace(c.value)) {
      spacePending = !result.empty();
      continue;
    }
    if (c.valid && isCombiningAccent(c.value)) {
      continue;
    }
    if (spacePending) {
      result += ' ';
      spacePending = false;
    }

    if (c.valid && c.value >= 'A' && c.value <= 'Z') {
      result += static_cast<char>(c.value - 'A' + 'a');
    } else if (c.valid && c.value >= 0xc0 && c.value < 0x180 &&
               !latinFolds[c.value - 0xc0].empty()) {
      result += latinFolds[c.value - 0xc0];
    } else if (c.valid && (c.value == 0x2018 || c.value == 0x2019)) {
      result += '\'';
    } else {
      result += bytes;
    }
  }
  return result;
}

}
