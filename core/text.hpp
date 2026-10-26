#pragma once

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

}
