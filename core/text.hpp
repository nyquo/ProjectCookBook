#pragma once

#include <cstddef>
#include <functional>
#include <string>
#include <string_view>

namespace core {

// Without leading and trailing ASCII whitespace
std::string_view trimmed(std::string_view text);

// The form under which two names are the same: lowercase, without accents,
// whitespace trimmed and collapsed to single spaces. " Crème  Fraîche " gives
// "creme fraiche". Folds ASCII and the Latin-1 and Latin Extended-A letters
// (œ gives "oe", ß "ss"), drops combining accents, counts no-break spaces as
// whitespace and typographic apostrophes as "'". Other characters stay as they
// are: Greek or Cyrillic capitals don't fold. Invalid UTF-8 bytes are kept.
std::string canonicalName(std::string_view name);

// The Unicode code points in UTF-8 text; an invalid byte counts as one, as in
// canonicalName()
std::size_t codePointCount(std::string_view text);
// Where code point `index` starts, in bytes; text.size() past the end
std::size_t byteOffset(std::string_view text, std::size_t index);

// Orders display names, e.g. by the user's locale
using NameLess = std::function<bool(std::string_view, std::string_view)>;

}
