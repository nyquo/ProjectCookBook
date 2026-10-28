#include "core/text.hpp"

#include <doctest/doctest.h>

// doctest prints std::string_view values through it
#include <ostream>

TEST_CASE("trimmed removes ASCII whitespace at both ends only")
{
  CHECK(core::trimmed(" \t\nMilk  \r") == "Milk");
  CHECK(core::trimmed("Crème  fraîche") == "Crème  fraîche");
  CHECK(core::trimmed(" \t ") == "");
}

TEST_CASE("canonicalName lowercases, removes accents, collapses whitespace")
{
  CHECK(core::canonicalName("Crème fraîche") == "creme fraiche");
  CHECK(core::canonicalName("  CRÈME \t\n FRAÎCHE  ") == "creme fraiche");
  CHECK(core::canonicalName("Bœuf haché") == "boeuf hache");
  CHECK(core::canonicalName("Œufs ÆBLE Straße") == "oeufs aeble strasse");
  CHECK(core::canonicalName("Jalapeño Çà Ÿ Ł Ž") == "jalapeno ca y l z");
  CHECK(core::canonicalName("Pâte d’amande") == "pate d'amande");
}

TEST_CASE("canonicalName counts no-break spaces as whitespace")
{
  // U+00A0 and U+202F, as French keyboards type before ";" and "!"
  CHECK(core::canonicalName("\xc2\xa0Pain\xe2\x80\xaf"
                            "complet\xc2\xa0") == "pain complet");
}

TEST_CASE("canonicalName drops combining accents")
{
  // "Crème" with U+0300 COMBINING GRAVE ACCENT after the e
  CHECK(core::canonicalName("Cre\xcc\x80me") == "creme");
}

TEST_CASE("canonicalName keeps what it doesn't fold")
{
  CHECK(core::canonicalName("1 × 2 ÷ 3") == "1 × 2 ÷ 3");
  CHECK(core::canonicalName("Ὀμελέτα 寿司") == "Ὀμελέτα 寿司");
  // An invalid byte, a truncated sequence and an overlong "/"
  CHECK(core::canonicalName("A\xff"
                            "B") == "a\xff"
                                    "b");
  CHECK(core::canonicalName("A\xc3") == "a\xc3");
  CHECK(core::canonicalName("\xc0\xaf") == "\xc0\xaf");
  CHECK(core::canonicalName("") == "");
}

TEST_CASE("codePointCount and byteOffset count Unicode code points")
{
  // "Émincez l’ail": É and ’ take 2 and 3 bytes
  const std::string_view text = "\xc3\x89mincez l\xe2\x80\x99"
                                "ail";
  CHECK(core::codePointCount(text) == 13);
  CHECK(core::byteOffset(text, 0) == 0);
  CHECK(core::byteOffset(text, 1) == 2);
  CHECK(core::byteOffset(text, 10) == 13);
  CHECK(core::byteOffset(text, 13) == text.size());
  CHECK(core::byteOffset(text, 20) == text.size());
  // A 4-byte code point, then an invalid byte that counts as one
  CHECK(core::codePointCount("\xf0\x9f\xa5\x95\xff") == 2);
  CHECK(core::codePointCount("") == 0);
}
